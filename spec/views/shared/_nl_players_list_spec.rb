# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_nl_players_list.html.erb", type: :view do
  describe "with players present" do
    let(:player1) do
      double("Character",
        id: 1,
        name: "HeroPlayer",
        level: 15,
        faction: "light",
        to_param: "1"
      )
    end

    let(:player2) do
      double("Character",
        id: 2,
        name: "DarkKnight",
        level: 20,
        faction: "dark",
        to_param: "2"
      )
    end

    let(:player3) do
      double("Character",
        id: 3,
        name: "NeutralGuy",
        level: 5,
        faction: nil,
        to_param: "3"
      )
    end

    before do
      assign(:players_here, [player1, player2, player3])

      # Stub respond_to? for faction check
      allow(player1).to receive(:respond_to?).with(:faction).and_return(true)
      allow(player2).to receive(:respond_to?).with(:faction).and_return(true)
      allow(player3).to receive(:respond_to?).with(:faction).and_return(true)
    end

    it "renders player entries" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-player-entry", count: 3)
    end

    it "displays player names as links" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_link("HeroPlayer")
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

    it "includes faction icon with correct class for light faction" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-faction-light")
    end

    it "includes faction icon with correct class for dark faction" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-faction-dark")
    end

    it "includes status indicator" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-player-status", count: 3)
    end

    it "links to character profile" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_link("HeroPlayer", href: profile_path(profile_name: "HeroPlayer"))
    end
  end

  describe "with no players" do
    before do
      assign(:players_here, [])
    end

    it "shows no players message" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-no-players")
      expect(rendered).to include("No other players here")
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

  describe "player without faction" do
    let(:player_no_faction) do
      double("Character",
        id: 1,
        name: "NoFaction",
        level: 10,
        faction: nil,
        to_param: "1"
      )
    end

    before do
      assign(:players_here, [player_no_faction])
      allow(player_no_faction).to receive(:respond_to?).with(:faction).and_return(true)
    end

    it "shows default icon for players without faction" do
      render partial: "shared/nl_players_list"

      expect(rendered).to have_css(".nl-player-icon")
      expect(rendered).not_to have_css(".nl-faction-light")
      expect(rendered).not_to have_css(".nl-faction-dark")
    end
  end
end
