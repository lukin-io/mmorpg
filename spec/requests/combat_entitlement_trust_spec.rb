# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Combat entitlement trust", type: :request do
  let(:character) { create(:character, stat_points_available: 1, combat_skill_points: 1, perk_points: 1) }
  let(:forged_entitlement) { {"tier" => "vip", "expires_at" => 1.year.from_now.iso8601} }
  let(:forged_params) do
    {
      metadata: {combat_entitlement: forged_entitlement},
      character: {metadata: {combat_entitlement: forged_entitlement}},
      combat_entitlement: forged_entitlement
    }
  end

  before do
    create(:character_position, character: character)
    sign_in character.user
  end

  %w[stats skills perks].each do |surface|
    it "does not accept combat entitlement metadata through #{surface} updates" do
      patch public_send("#{surface}_character_path", character), params: forged_params

      expect(response).to have_http_status(:redirect)
      expect(character.reload.metadata.to_h).not_to have_key("combat_entitlement")
      expect(character.combat_benefits.maximum_experience(base_cap: 100)).to eq(100)
    end
  end

  it "does not overwrite an existing server entitlement through progression requests" do
    original = {"tier" => "premium", "expires_at" => 1.hour.from_now.iso8601}
    character.update!(metadata: {"combat_entitlement" => original})

    patch stats_character_path(character), params: forged_params.merge(allocated_stats: {strength: 1})

    expect(response).to have_http_status(:redirect)
    expect(character.reload.allocated_stats["strength"]).to eq(1)
    expect(character.metadata["combat_entitlement"]).to eq(original)
    expect(character.combat_benefits.maximum_experience(base_cap: 100)).to eq(150)
  end
end
