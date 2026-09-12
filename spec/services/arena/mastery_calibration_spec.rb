# frozen_string_literal: true

require "rails_helper"
RSpec.describe Arena::CombatProfile, "mastery calibration" do
  [["blunt", "bludgeoning_mastery", 72, 150, 62], ["knife", "knife_mastery", 66, 130, 58]].each do |family, skill, base, mastery, expected|
    it "reproduces #{family} base #{base} and mastery #{mastery}" do
      character = create(:character, passive_skills: {skill => 100})
      weapon = create(:item_template, slot: "main_hand", requirements: {"ap" => base}, stat_modifiers: {"weapon_family" => family, skill => mastery - 100})
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: weapon)
      participation = create(:arena_participation, character:)
      expect(described_class.physical_attack_seed(participation)).to eq(expected)
      expect(described_class.for_character(character).fetch("physical_attack_cost_seed")).to eq(expected)
      expect(described_class.attack_cost(participation, :aimed)).to eq(expected + 20)
    end
  end

  it "reproduces the observed 65-AP mace and off-hand dagger profile and restores the single weapon after removal" do
    character = create(:character, passive_skills: {"bludgeoning_mastery" => 100, "knife_mastery" => 100})
    mace = create(:item_template, slot: "main_hand", requirements: {"ap" => 72}, stat_modifiers: {"weapon_family" => "blunt", "bludgeoning_mastery" => 50})
    knife = create(:item_template, slot: "off_hand", requirements: {"ap" => 66}, stat_modifiers: {"weapon_family" => "knife", "knife_mastery" => 30})
    create(:inventory_item, :equipped, inventory: character.inventory, item_template: mace, equipment_slot: "main_hand")
    off_hand = create(:inventory_item, :equipped, inventory: character.inventory, item_template: knife, equipment_slot: "off_hand")
    participation = create(:arena_participation, character:)
    expect(described_class.physical_attack_seed(participation)).to eq(65)
    expect(described_class.for_character(character).fetch("physical_attack_cost_seed")).to eq(65)
    expect(character.weapon_mastery).to eq(140)
    off_hand.update!(equipped: false, equipment_slot: nil)
    expect(described_class.physical_attack_seed(participation)).to eq(62)
  end
end
