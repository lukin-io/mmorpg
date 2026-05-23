# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World Interactions", type: :system, js: true do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character, user: user) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

  before do
    login_as(user, scope: :user)
    (3..7).each do |x|
      (3..7).each do |y|
        create(:map_tile_template, zone: zone.name, x:, y:, terrain_type: "outdoor", passable: true)
      end
    end
  end

  describe "success cases" do
    it "starts timed movement, then resumes at the destination after completion" do
      visit world_path

      expect(page).to have_css(".nl-location-coords", text: "[5, 5]")

      find(".nl-tile-clickable--available[data-target-x='6'][data-target-y='5']").click

      expect(page).to have_css(".nl-cursor-img--moving")
      expect(page).to have_css(".nl-location-coords", text: "[5, 5]")
      expect(position.reload.x).to eq(5)

      MovementCommand.moving.last.update!(ends_at: 1.second.ago)
      visit world_path

      expect(page).to have_css(".nl-location-coords", text: "[6, 5]")
    end

    it "enters a tile building and transitions zones" do
      destination_zone = create(:zone, name: "Форпост", location_type: "city", width: 10, height: 10)
      create(:tile_building,
        :with_destination,
        zone: zone.name,
        x: position.x,
        y: position.y,
        name: "Ворота Форпоста",
        destination_zone: destination_zone,
        destination_x: 2,
        destination_y: 3)

      visit world_path

      click_button "Войти"

      expect(page).to have_content("Форпост")
    end
  end

  describe "null/edge cases" do
    it "does not offer out-of-bounds movement tiles at the map boundary" do
      position.update!(x: 0, y: 0)

      visit world_path

      expect(page).not_to have_css(".direction-btn")
      expect(page).not_to have_css(".nl-tile-clickable--available[data-target-x='-1']")
      expect(page).not_to have_css(".nl-tile-clickable--available[data-target-y='-1']")
    end
  end

  describe "authorization cases" do
    it "redirects unauthenticated users to login" do
      logout(:user)

      visit world_path

      expect(page).to have_current_path(/sign_in/).or have_content("Вход")
    end
  end
end
