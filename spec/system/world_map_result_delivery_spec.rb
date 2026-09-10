# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World timer-frame result delivery", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 20, y: 20) }
  let!(:tile) { create(:map_tile_template, :with_resource_search, zone: zone.name, x: 20, y: 20) }

  it "updates a pending result dialog alongside a timer-frame response without reloading the page" do
    login_as(user, scope: :user)
    visit world_path
    expect(page).to have_css(".nl-map-container[data-viewport-ready='true']")
    buffer_size = page.all(".nl-map-tile", visible: :all).size
    expect(page).to have_button("Look Around")
    page.execute_script("window.pendingResultMapCell = document.getElementById('tile_20_20')")
    page.evaluate_async_script(<<~JS)
      const done = arguments[arguments.length - 1]
      const form = document.querySelector('.nl-world-action-form')
      // Preserve the action's redirect flash, as when another timer request
      // reaches the server before the ordinary action redirect is followed.
      fetch(form.action, {
        method: 'POST', body: new FormData(form), credentials: 'same-origin',
        redirect: 'manual', headers: {Accept: 'text/vnd.turbo-stream.html'}
      }).then(() => done()).catch(error => done(String(error)))
    JS
    page.execute_script(<<~JS)
      document.querySelector('[data-nl-world-map-target="refreshForm"]').requestSubmit()
    JS

    expect(page).to have_css('dialog[open]', text: "There is no useful vegetation in this area.")
    expect(page).to have_css(".nl-map-tile", count: buffer_size)
    expect(page).to have_css('.nl-map-container[data-nl-world-map-work-active-value="true"]')
    expect(page).to have_css('body.nl-game-layout', count: 1)
    expect(page.evaluate_script("window.pendingResultMapCell === document.getElementById('tile_20_20')")).to be(true)
    expect(position.reload).to have_attributes(x: 20, y: 20)
    action = WorldActionOffer.accepted.find_by!(character:, target: tile)
    expect(action.metadata["local_action_result_delivered_at"]).to be_present

    # The observed modal stays open after the work deadline until Close. A
    # normal timer refresh must not replace the result owner with empty HTML.
    page.execute_script("window.pendingResultDialog = document.querySelector('dialog[open]')")
    action.update!(accepted_at: 30.seconds.ago,
      metadata: action.metadata.merge("local_action_ends_at" => 1.second.ago.iso8601(3)))
    page.execute_script(<<~JS)
      document.querySelector('[data-nl-world-map-target="refreshForm"]').requestSubmit()
    JS
    expect(page).to have_css('.nl-map-container[data-nl-world-map-work-active-value="false"]')
    expect(page).to have_css('dialog[open]', text: "There is no useful vegetation in this area.")
    expect(page.evaluate_script("window.pendingResultDialog === document.querySelector('dialog[open]')")).to be(true)
    expect(action.reload).to be_completed
  end

  it "keeps a normal Drink result open when its automatic timer finishes" do
    character.update!(fatigue_percent: 7, fatigue_updated_at: Time.current)
    tile.update!(metadata: {"local_actions" => [{"type" => "drinking", "source_id" => "dri"}]})
    login_as(user, scope: :user)
    visit world_path
    expect(page).to have_css(".nl-map-container[data-viewport-ready='true']")
    click_button "Drink"

    expect(page).to have_css('dialog[open]', text: "Everything went well.")
    expect(page).to have_button("Drink", disabled: true)
    expect(page).to have_css(".nl-map-container[data-viewport-ready='true']")
    page.execute_script(<<~JS)
      window.drinkResultDialog = document.querySelector('dialog[open]')
      window.drinkResultMapCell = document.getElementById('tile_20_20')
    JS
    action = WorldActionOffer.accepted.find_by!(character:, action_type: "drink")

    travel_to(action.local_action_ends_at + 1.second) do
      page.execute_script(<<~JS)
        const originalNow = Date.now.bind(Date)
        Date.now = () => originalNow() + 61000
      JS
      expect(page).to have_css('.nl-map-container[data-nl-world-map-work-active-value="false"]')
      expect(page).to have_button("Drink", disabled: false)
      expect(page).to have_css('dialog[open]', text: "Everything went well.")
      expect(page.evaluate_script("window.drinkResultDialog === document.querySelector('dialog[open]')")).to be(true)
      expect(page.evaluate_script("window.drinkResultMapCell === document.getElementById('tile_20_20')")).to be(true)
      expect(action.reload).to be_completed
      expect(character.reload.fatigue_percent).to eq(5)
    end
  end
end
