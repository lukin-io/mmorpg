# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena NPC immediate start", type: :system, js: true do
  let(:user) { create(:user, email: "arena-npc-browser@test.com", password: "password123") }
  let(:zone) { create(:zone, name: "Arena Browser City", location_type: "city") }
  let(:character) { create(:character, user:, name: "ArenaNpcBrowser", level: 5) }
  let!(:position) { create(:character_position, character:, zone:, x: 0, y: 0) }
  let!(:arena_hotspot) do
    create(
      :city_hotspot,
      :arena,
      zone:,
      active: true,
      required_level: 1
    )
  end
  let(:room) do
    create(
      :arena_room,
      name: "Training Hall",
      slug: "training",
      level_min: 5,
      level_max: 10,
      active: true,
      room_type: :training
    )
  end
  let(:npc) do
    create(
      :npc_template,
      npc_key: "arena_training_dummy",
      name: "Training Dummy",
      role: "arena_bot",
      level: 1,
      metadata: {
        "health" => 30,
        "base_damage" => 1,
        "ai_behavior" => "passive",
        "arena_rooms" => ["training"]
      }
    )
  end
  let!(:application) do
    create(
      :arena_application,
      arena_room: room,
      applicant: nil,
      npc_template: npc,
      status: :open,
      fight_type: :duel,
      fight_kind: :free,
      timeout_seconds: 300,
      trauma_percent: 30
    )
  end

  before { login_as(user, scope: :user) }

  it "follows the server's zero-second NPC countdown into the live fight" do
    visit world_path
    click_button "Arena"
    expect(page).to have_current_path(arena_index_path)
    visit arena_room_path(room)

    click_button "Accept"

    expect(page).to have_current_path(%r{\A/arena_matches/\d+\z}, wait: 5)
    match = application.reload.arena_match
    expect(page).to have_current_path(arena_match_path(match))
    expect(page).to have_css(".arena-match-page")
    expect(page).to have_content("Training Dummy")
    expect(match).to be_live
  end
end
