# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World Interactions", type: :system, js: true do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Adventure Plains", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character, user: user) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

  before do
    login_as(user, scope: :user)
  end

  describe "success cases" do
    it "starts timed movement, then resumes at the destination after completion" do
      visit world_path

      expect(page).to have_css(".nl-location-coords", text: "[5, 5]")

      click_button "East →"

      expect(page).to have_css(".movement-cooldown", text: /Moving/i)
      expect(page).to have_css(".nl-location-coords", text: "[5, 5]")
      expect(position.reload.x).to eq(5)

      MovementCommand.moving.last.update!(ends_at: 1.second.ago)
      visit world_path

      expect(page).to have_css(".nl-location-coords", text: "[6, 5]")
    end

    it "enters a tile building and transitions zones" do
      destination_zone = create(:zone, name: "Hidden Hamlet", location_type: "outdoor", width: 10, height: 10)
      create(:tile_building,
        :with_destination,
        zone: zone.name,
        x: position.x,
        y: position.y,
        name: "Town Gate",
        destination_zone: destination_zone,
        destination_x: 2,
        destination_y: 3)

      visit world_path

      click_button "🚪 Enter Town Gate"

      expect(page).to have_content("Hidden Hamlet")
    end
  end

  describe "null/edge cases" do
    it "disables movement buttons at the map boundary" do
      position.update!(x: 0, y: 0)

      visit world_path

      expect(page).to have_css(".direction-btn--disabled", text: "↑")
      expect(page).to have_css(".direction-btn--disabled", text: "←")
    end
  end

  describe "authorization cases" do
    it "redirects unauthenticated users to login" do
      logout(:user)

      visit world_path

      expect(page).to have_current_path(/sign_in/).or have_content("Log in")
    end
  end
end
