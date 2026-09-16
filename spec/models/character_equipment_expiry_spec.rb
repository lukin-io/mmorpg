# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Equipment effect expiry", type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it "removes every equipment input at expiry while preserving inventory and stored fight AP" do
    character = create(:character, level: 10, current_hp: 3, current_mp: 1)
    expiry = Time.current.change(usec: 0) + 10.minutes
    template = create(:item_template, slot: "main_hand", requirements: {"ap" => 60}, stat_modifiers: {
      "strength" => 5, "vitality" => 4, "weapon_family" => "knife", "attack" => 10,
      "accuracy" => 20, "armor_class" => 8, "knife_skill" => 30, "doctor" => 100,
      "skill_bonuses" => {"extra_action_points" => 20}, "block_table" => "shield_70"
    })
    item = create(:inventory_item, inventory: character.inventory, item_template: template,
      equipped: true, properties: {"expires_at" => expiry.iso8601})
    participation = create(:arena_participation, character:, user: character.user)
    profile = Arena::CombatProfile.persist!(participation)

    travel_to(expiry - 1.second) do
      expect(item).to be_usable_equipment
      expect(character.stats.get(:strength)).to eq(6)
      expect(character.passive_skill_level(:knife_mastery)).to eq(30)
      expect(character.doctor_proficiency).to eq(100)
      expect(character.accuracy_bonus).to eq(20)
    end
    travel_to(expiry) do
      expect(item).to be_expired
      expect(character.stats.get(:strength)).to eq(1)
      expect(character.passive_skill_level(:knife_mastery)).to eq(0)
      expect(character.doctor_proficiency).to eq(0)
      expect(character.accuracy_bonus).to eq(0)
      expect(character.armor_class).to eq(0)
      expect(character.combat_weapons).to be_empty
      expect(Arena::CombatProfile.for_character(character)).to include("physical_attack_cost_seed" => 45, "block_table" => "normal")
      expect(Arena::CombatProfile.for_participation(participation.reload)).to eq(profile)
      expect(character.reload).to have_attributes(current_hp: 3, current_mp: 1)
      expect(item.reload).to be_equipped
    end
    travel_to(expiry + 1.second) { expect(item).not_to be_usable_equipment }
  end

  it "fails closed for a malformed declared expiry but permits undated equipment" do
    item = build(:inventory_item, equipped: true, properties: {"expires_at" => "invalid"})
    expect(item).not_to be_usable_equipment
    item.properties = {}
    expect(item).to be_usable_equipment
  end

  it "naturally expires injury penalties without healing or rewriting the character" do
    character = create(:character, allocated_stats: {"strength" => 19}, current_hp: 1)
    expiry = Time.current.change(usec: 0) + 1.minute
    CharacterInjury.create!(character:, severity: "light", name: "Test injury", expires_at: expiry, stat_penalty_percent: 20)
    character.reload
    travel_to(expiry - 1.second) { expect(character.stats.get(:strength)).to eq(16) }
    travel_to(expiry) do
      expect(character.stats.get(:strength)).to eq(20)
      expect(character.reload.current_hp).to eq(1)
      expect(character.allocated_stats).to eq("strength" => 19)
    end
  end
end
