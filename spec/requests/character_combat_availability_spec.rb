# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Character allocation during combat", type: :request do
  let(:user) { create(:user) }
  let!(:character) { create(:character, user:, stat_points_available: 4, combat_skill_points: 4, perk_points: 2) }

  before { sign_in user, scope: :user }

  [{}, {"physical_only" => true}, {"source" => "wilderness"}].each do |metadata|
    it "rejects all allocation endpoints for active #{metadata.inspect} fights without spending" do
      match = create(:arena_match, status: :live, metadata:)
      create(:arena_participation, arena_match: match, character:, user:, team: "a")
      original = character.reload.attributes.slice("allocated_stats", "passive_skills", "perks", "stat_points_available", "combat_skill_points", "perk_points")

      [
        [stats_character_path(character), {allocated_stats: {strength: 1}}],
        [skills_character_path(character), {allocated_skills: {unarmed_combat: 1}}],
        [perks_character_path(character), {selected_perks: {more_strength: "1"}}]
      ].each do |path, values|
        patch path, params: values, as: :json
        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body).to include("error" => "arena_reserved", "redirect_url" => arena_match_path(match))
        expect(character.reload.attributes.slice(*original.keys)).to eq(original)
      end
    end
  end
end
