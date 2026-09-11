# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shared flash lifecycle", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:city) { create(:zone, :city_node, name: "Flash Central Square") }
  let!(:position) { create(:character_position, character:, zone: city, x: 0, y: 0) }
  let!(:shop) { create(:city_hotspot, :shop, zone: city) }

  def sign_in_through_form
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"
    expect(page).to have_css(".nl-city-scene")
  end

  def enter_shop
    within(".city-actions") { click_button "Shop" }
    expect(page).to have_css(".nl-shop-page")
    expect(page).to have_css("#flash [role='status']", text: "Entered Shop.")
  end

  it "expires real sign-in and Shop notices while preserving the shared stream target" do
    sign_in_through_form
    expect(page).to have_css("#flash [role='status']", text: "Signed in successfully.")
    expect(page).to have_no_css("#flash .nl-flash", wait: 7)
    expect(page).to have_css("#flash", visible: :all)

    enter_shop
    expect(page).to have_no_css("#flash .nl-flash", wait: 7)
    expect(page).to have_css("#flash", visible: :all)
    expect(page).to have_css(".nl-shop-page")
  end

  it "clears an old outer notice as soon as a Shop filter replaces only the gameplay frame" do
    login_as(user, scope: :user)
    visit world_path
    enter_shop
    page.execute_script("document.body.dataset.flashNavigationProbe = 'same-shell'")

    within(".nl-shop-categories") { click_link "Other" }

    expect(page).to have_css(".nl-shop-category[aria-label='Other'][aria-current='page']")
    expect(page).to have_css("body[data-flash-navigation-probe='same-shell']")
    expect(page).to have_no_css("#flash .nl-flash", wait: 1)
    expect(page).to have_css("#flash", visible: :all)
  end

  it "does not revive an old Shop notice when browser Back restores the page" do
    login_as(user, scope: :user)
    visit world_path
    enter_shop

    within(".nl-top-nav") { click_link "City" }
    expect(page).to have_css(".nl-city-scene")
    page.go_back

    expect(page).to have_css(".nl-shop-page")
    expect(page).to have_no_css("#flash .nl-flash", wait: 1)
    expect(page).to have_css("#flash", visible: :all)
  end

  it "keeps a streamed error through chat refresh and an older notice timer, then allows dismissal" do
    sign_in_through_form
    expect(page).to have_css("#flash [role='status']", text: "Signed in successfully.")
    expect(page).to have_css("#chat_timeline")
    find(".nl-chat-input-field").set("%<Someone> private test")
    find(".nl-chat-input-field").send_keys(:enter)

    expect(page).to have_css("#flash [role='alert']", text: "Private messaging is not available here.")
    expect(page).to have_no_css("#flash [role='status']")

    # This is a real unrelated frame refresh. It must not dismiss the error,
    # and a disconnected success notice must not later remove its replacement.
    page.execute_script("document.getElementById('chat_messages').reload()")
    expect(page).to have_css("#chat_timeline")
    Capybara.using_wait_time(7) do
      page.evaluate_async_script("const done = arguments[arguments.length - 1]; setTimeout(done, 5100)")
    end

    expect(page).to have_css("#flash [role='alert']", text: "Private messaging is not available here.")
    find("#flash button[aria-label='Dismiss notification']").send_keys(:enter)
    expect(page).to have_no_css("#flash .nl-flash")
    expect(page).to have_css("#flash", visible: :all)
    expect(page).to have_no_css("#chat_timeline article", text: "private test")
  end
end
