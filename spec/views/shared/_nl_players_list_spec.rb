# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_nl_players_list.html.erb", type: :view do
  describe "with players present" do
    let(:player1) do
      double("Character",
        id: 1,
        name: "max_kerby_list",
        level: 15,
        alignment: "light",
        to_param: "1")
    end

    let(:player2) do
      double("Character",
        id: 2,
        name: "DarkKnight",
        level: 20,
        alignment: "dark",
        to_param: "2")
    end

    let(:player3) do
      double("Character",
        id: 3,
        name: "NeutralGuy",
        level: 5,
        alignment: nil,
        to_param: "3")
    end

    before do
      assign(:players_here, [player1, player2, player3])

      allow(player1).to receive(:respond_to?).with(:alignment).and_return(true)
      allow(player2).to receive(:respond_to?).with(:alignment).and_return(true)
      allow(player3).to receive(:respond_to?).with(:alignment).and_return(true)
    end

    it "renders player entries" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-player-entry", count: 3)
    end

    it "displays player names as links" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_link("max_kerby_list")
      expect(rendered).to have_link("DarkKnight")
      expect(rendered).to have_link("NeutralGuy")
    end

    it "displays player levels in brackets" do
      render partial: "shared/nl_players_list"

      expect(rendered).to include("[15]")
      expect(rendered).to include("[20]")
      expect(rendered).to include("[5]")
    end

    it "includes arrow indicator" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-player-arrow", count: 3)
    end

    it "includes alignment icon with correct class for light alignment" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-alignment-light")
    end

    it "includes alignment icon with correct class for dark alignment" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-alignment-dark")
    end

    it "includes status indicator" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-player-status", count: 3)
    end

    it "links to character profile" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_link("max_kerby_list", href: player_path(name: "max_kerby_list"))
    end
  end

  describe "with no players" do
    before do
      assign(:players_here, [])
    end

    it "shows no players message" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-no-players")
      expect(rendered).to include("No players nearby")
    end

    it "does not render player entries" do
      render partial: "shared/nl_players_list"

      expect(rendered).not_to have_css(".nl-player-entry")
    end
  end

  describe "with nil players_here" do
    before do
      assign(:players_here, nil)
    end

    it "handles nil gracefully" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-no-players")
    end
  end

  describe "player without alignment" do
    let(:player_no_alignment) do
      double("Character",
        id: 1,
        name: "NoAlignment",
        level: 10,
        alignment: nil,
        to_param: "1")
    end

    before do
      assign(:players_here, [player_no_alignment])
      allow(player_no_alignment).to receive(:respond_to?).with(:alignment).and_return(true)
    end

    it "shows default icon for players without alignment" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-player-icon")
      expect(rendered).not_to have_css(".nl-alignment-light")
      expect(rendered).not_to have_css(".nl-alignment-dark")
    end
  end
end
