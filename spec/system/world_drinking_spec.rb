# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World drinking", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let(:character) { create(:character, fatigue_percent: 7, fatigue_updated_at: Time.current, passive_skills: {}, perks: {}) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let!(:pond) do
    create(:map_tile_template, zone: zone.name, x: 5, y: 5,
      metadata: {"local_actions" => [
        {"type" => "resource_search", "source_id" => "look"},
        {"type" => "fishing", "source_id" => "fis"},
        {"type" => "drinking", "source_id" => "dri"}
      ]})
  end

  before { login_as(character.user, scope: :user) }
  after { travel_back }

  it "shows immediate success, retains the sip lock through dismissal/reload, and restores actions on time" do
    visit world_path
    click_button "Drink"

    expect(page).to have_css("dialog[open][aria-label='Action result']", text: "Everything went well.")
    expect(page).to have_button("Drink", disabled: true)
    expect(page).to have_button("Fish", disabled: true)
    expect(page).to have_button("Look Around", disabled: true)
    expect(page).to have_button("Inventory", disabled: true)
    expect(page).to have_button("Your character", disabled: true)
    expect(page).to have_no_css(".nl-tile-clickable--available")
    expect(find(".nl-timer-seconds").text.to_i).to be_between(50, 60)
    offer = WorldActionOffer.accepted.find_by!(character:, action_type: "drink")
    deadline = offer.local_action_ends_at
    expect(character.reload.fatigue_percent).to eq(5)

    within("dialog") { find("button[aria-label='Close result']").click }
    page.refresh
    expect(page).to have_no_css("dialog")
    expect(page).to have_button("Drink", disabled: true)
    expect(page).to have_button("Fish", disabled: true)
    expect(page).to have_button("Look Around", disabled: true)
    expect(offer.reload.local_action_ends_at).to eq(deadline)
    expect(character.reload.fatigue_percent).to eq(5)

    travel_to(deadline + 1.second)
    page.execute_script(<<~JS)
      const originalNow = Date.now.bind(Date)
      Date.now = () => originalNow() + 61000
    JS
    expect(page).to have_css(".nl-map-container[data-nl-world-map-work-active-value='false']")
    expect(page).to have_button("Drink", disabled: false)
    expect(page).to have_button("Fish", disabled: false)
    expect(page).to have_button("Look Around", disabled: false)
    expect(page).to have_button("Inventory", disabled: false)
    expect(offer.reload).to be_completed
    expect(character.reload.fatigue_percent).to eq(5)
    expect(position.reload).to have_attributes(zone:, x: 5, y: 5)
  end
end
