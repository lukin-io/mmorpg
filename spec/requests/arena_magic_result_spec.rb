# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Completed mixed physical and magic damage", type: :request do
  it "keeps elemental damage separate from physical in the final result" do
    character = create(:character)
    match = create(:arena_match, status: :completed, winning_team: "a", metadata: {"rewards_processed_at" => Time.current.iso8601})
    create(:arena_participation, arena_match: match, character:, user: character.user, team: "a", result: :victory,
      metadata: {"damage_dealt" => 155, "damage_by_element" => {"physical" => 145, "arcane" => 10}, "opponents_defeated" => 1, "experience_awarded" => 2})
    sign_in character.user

    get arena_match_path(match)

    table = Nokogiri::HTML(response.body).at_css(".nl-fight-result-table")
    expect(table.css("th").map(&:text)).to eq(%w[Character Physical Magic Total XP])
    expect(table.css("tbody td").map(&:text).map(&:strip)).to eq(["#{character.name}[1]", "145(1)", "10", "155(1)", "2"])
  end
end
