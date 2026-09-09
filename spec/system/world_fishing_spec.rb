# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World fishing entry", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let(:character) { create(:character, fatigue_percent: 7, fatigue_updated_at: Time.current, passive_skills: {}) }
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

  it "shows the empty-bait result and restores the 30-second action lock without a catch" do
    visit world_path
    original_items = character.inventory.inventory_items.pluck(:id, :quantity)
    click_button "Fish"

    expect(page).to have_css("dialog[open][aria-label='Action result']", text: "No bait available.")
    expect(page).to have_button("Fish", disabled: true)
    expect(page).to have_button("Drink", disabled: true)
    expect(page).to have_button("Look Around", disabled: true)
    expect(page).to have_button("Inventory", disabled: true)
    expect(page).to have_no_css(".nl-tile-clickable--available")
    expect(find(".nl-timer-seconds").text.to_i).to be_between(20, 30)
    offer = WorldActionOffer.accepted.find_by!(character:, action_type: "fish")
    deadline = offer.local_action_ends_at

    within("dialog") { click_button "Close", exact: true }
    page.refresh
    expect(page).to have_no_css("dialog")
    expect(page).to have_button("Fish", disabled: true)
    expect(page).to have_button("Drink", disabled: true)
    expect(page).to have_button("Look Around", disabled: true)
    expect(offer.reload.local_action_ends_at).to eq(deadline)

    travel_to(deadline + 1.second)
    page.refresh
    expect(page).to have_button("Fish", disabled: false)
    expect(page).to have_button("Drink", disabled: false)
    expect(page).to have_button("Look Around", disabled: false)
    expect(offer.reload).to be_completed
    expect(character.reload.fatigue_percent).to eq(7)
    expect(character.passive_skills).to eq({})
    expect(character.inventory.inventory_items.pluck(:id, :quantity)).to eq(original_items)
    expect(position.reload).to have_attributes(zone:, x: 5, y: 5)
  end
end
