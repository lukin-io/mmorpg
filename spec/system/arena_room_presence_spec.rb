# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena room entry presence", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, name: "RoomViewer", level: 10) }
  let(:city) { create(:zone, :city, name: "Arena City") }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:hotspot) { create(:city_hotspot, :arena, zone: city) }
  let!(:current_room) { create(:arena_room, zone: city, name: "First Hall", room_type: :training) }
  let!(:next_room) { create(:arena_room, zone: city, name: "Second Hall", room_type: :trial) }

  def online_room_player(name:, room:)
    create(:character, name:, level: 10).tap do |player|
      create(:character_position, character: player, zone: city, x: 5, y: 5)
      create(:user_session, user: player.user)
      Game::World::ResumeContext.new(character: player).remember_arena_room!(room:)
    end
  end

  before do
    online_room_player(name: "PreviousRoomNeighbor", room: current_room)
    online_room_player(name: "NewRoomNeighbor", room: next_room)
    online_room_player(name: "SecondRoomNeighbor", room: next_room)
    Game::World::ResumeContext.new(character:).remember_arena_room!(room: current_room)
    login_as(user, scope: :user)
  end

  {
    "summary" => ".nl-arena-summary-table",
    "Room Map" => ".nl-arena-room-scheme"
  }.each do |entry, selector|
    it "updates the full room audience immediately through the #{entry} Enter link" do
      visit arena_index_path
      expect(page).to have_css(".nl-location-text", text: "First Hall [ 2 ]")
      expect(page).to have_css(".nl-player-entry", text: "PreviousRoomNeighbor")
      find(".nl-refresh-check input").uncheck
      click_button "Room Map" if entry == "Room Map"

      within(selector) { find("a[href='#{arena_room_path(next_room, ft: 1)}']").click }

      expect(page).to have_css(".nl-arena-frame[data-arena-room-id-value='#{next_room.id}']")
      expect(character.reload.gameplay_context).to eq(
        "name" => "arena_room", "params" => {"room_id" => next_room.id}
      )
      expect(page).to have_css(".nl-location-text", text: "Second Hall [ 3 ]")
      expect(page).to have_css(".nl-player-entry", text: "RoomViewer")
      expect(page).to have_css(".nl-player-entry", text: "NewRoomNeighbor")
      expect(page).to have_css(".nl-player-entry", text: "SecondRoomNeighbor")
      expect(page).to have_no_css(".nl-player-entry", text: "PreviousRoomNeighbor")
      expect(page).to have_css("#chat_timeline", count: 1)
      expect(position.reload).to have_attributes(zone: city, x: 5, y: 5)

      saved_chat_context = character.metadata.fetch("local_chat_context")
      visit arena_room_path(next_room)
      expect(page).to have_css(".nl-location-text", text: "Second Hall [ 3 ]")
      expect(character.reload.metadata.fetch("local_chat_context")).to eq(saved_chat_context)
    end
  end
end
