# frozen_string_literal: true

require "rails_helper"

RSpec.describe Character, type: :model do
  let(:character) { create(:character, level: 10) }

  describe "equipment combat inputs" do
    it "keeps modifiers distinct from primary stats, weapon mastery and physical resistance" do
      character.update!(allocated_stats: {"dexterity" => 40, "vitality" => 50, "luck" => 60},
        passive_skills: {"bludgeoning_mastery" => 100, "physical_damage_resistance" => 30})
      template = create(:item_template, stat_modifiers: {
        "armor_class" => 7, "accuracy" => "+15%", "evasion" => "-5%",
        "crushing" => "140%", "fortitude" => "25%", "physical_resistance" => 55,
        "armor_pierce" => 12, "dexterity" => 3,
        "skill_bonuses" => {"bludgeoning_mastery" => 50, "physical_damage_resistance" => 10}
      })
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: template,
        properties: {"effects" => {"accuracy" => 20}})

      expect(character.armor_class).to eq(7)
      expect(character.accuracy_bonus).to eq(20)
      expect(character.dodge_bonus).to eq(-5)
      expect(character.crushing_percent).to eq(140)
      expect(character.fortitude_percent).to eq(25)
      expect(character.armor_pierce_percent).to eq(12)
      expect(character.passive_skill_level(:bludgeoning_mastery)).to eq(150)
      expect(character.passive_skill_level(:physical_damage_resistance)).to eq(40)
      expect(character.stats.get(:dexterity)).to eq(44)
    end

    it "sums actual item armor aliases without derived primary-stat defense" do
      character.update!(allocated_stats: {"strength" => 50, "vitality" => 50})
      {"armor_class" => 7, "armor" => 4, "defense" => 2}.each do |key, value|
        template = create(:item_template, stat_modifiers: {key => value})
        create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)
      end

      expect(character.armor_class).to eq(13)
    end

    it "does not infer Fortitude from physical resistance or Health" do
      character.update!(allocated_stats: {"vitality" => 50},
        passive_skills: {"physical_damage_resistance" => 100})
      template = create(:item_template, stat_modifiers: {"physical_resistance" => 80})
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)

      expect(character.fortitude_percent).to eq(0)
    end

    it "excludes broken and carried equipment from modifier totals" do
      template = create(:item_template, :durable, stat_modifiers: {
        "armor_class" => 7, "accuracy" => 20, "evasion" => 15,
        "crushing" => 140, "fortitude" => 25, "armor_pierce" => 12
      })
      create(:inventory_item, :equipped, :broken, inventory: character.inventory, item_template: template)
      create(:inventory_item, inventory: character.inventory, item_template: template)

      expect(character.armor_class).to eq(0)
      expect(character.accuracy_bonus).to eq(0)
      expect(character.dodge_bonus).to eq(0)
      expect(character.crushing_percent).to eq(0)
      expect(character.fortitude_percent).to eq(0)
      expect(character.armor_pierce_percent).to eq(0)
    end
  end

  describe "allocation uses learned levels" do
    before do
      template = create(:item_template, stat_modifiers: {"knife_skill" => 30})
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)
    end

    it "increments learned levels without persisting equipment bonuses" do
      character.update!(passive_skills: {"knife_mastery" => 20})

      character.increase_passive_skill!(:knife_mastery, 5)

      expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(25)
      expect(character.passive_skill_level(:knife_mastery)).to eq(55)
    end

    it "keeps increment and setter caps on learned levels" do
      character.update!(passive_skills: {"knife_mastery" => 98})

      character.increase_passive_skill!(:knife_mastery, 5)

      expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(100)
      expect(character.passive_skill_level(:knife_mastery)).to eq(130)
      character.set_passive_skill!(:knife_mastery, 150)
      expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(100)
    end

    it "previews the learned tier and cap even when equipment crosses them" do
      character.update!(passive_skills: {"knife_mastery" => 24})
      expect(character.skill_points_per_spend(:knife_mastery)).to eq(8)

      character.update!(passive_skills: {"knife_mastery" => 98})
      expect(character.skill_points_per_spend(:knife_mastery)).to eq(2)

      character.update!(passive_skills: {"knife_mastery" => 100})
      expect(character.skill_points_per_spend(:knife_mastery)).to eq(0)
    end

    it "spends and refunds learned levels while retaining equipment in the effective total" do
      character.update!(combat_skill_points: 2, passive_skills: {"knife_mastery" => 98})

      expect(character.spend_skill_point!(:knife_mastery)).to eq(100)
      expect(character.reload.combat_skill_points).to eq(1)
      expect(character.passive_skill_level(:knife_mastery)).to eq(130)
      expect(character.spend_skill_point!(:knife_mastery)).to be_nil
      expect(character.reload.combat_skill_points).to eq(1)

      expect(character.refund_skill_point!(:knife_mastery, base_level: 98)).to eq(98)
      expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(98)
      expect(character.passive_skill_level(:knife_mastery)).to eq(128)
      expect(character.combat_skill_points).to eq(2)
      expect(character.refund_skill_point!(:knife_mastery, base_level: 98)).to be_nil
      expect(character.reload.combat_skill_points).to eq(2)
    end

    it "does not refund equipment as if it were a new learned allocation" do
      character.update!(combat_skill_points: 2, passive_skills: {"knife_mastery" => 90})

      expect(character.refund_skill_point!(:knife_mastery, base_level: 90)).to be_nil
      expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(90)
      expect(character.combat_skill_points).to eq(2)
    end

    it "retains effective values for equipment requirements" do
      character.update!(passive_skills: {"knife_mastery" => 100})
      template = create(:item_template, requirements: {"knife_mastery" => 130})
      item = create(:inventory_item, inventory: character.inventory, item_template: template)

      expect(Game::Inventory::RequirementChecker.call(character:, item:)).to include(allowed: true)
    end
  end

  describe "effective skill handoff" do
    it "retains the captured 130/150 mastery totals without changing saved allocation" do
      character.update!(passive_skills: {"knife_mastery" => 100, "bludgeoning_mastery" => 100})
      template = create(:item_template, stat_modifiers: {
        "knife_skill" => 30, "skill_bonuses" => {"bludgeoning_mastery" => 50}
      })
      item = create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)

      expect(character.passive_skill_level(:knife_mastery)).to eq(130)
      expect(character.passive_skill_level(:bludgeoning_mastery)).to eq(150)
      expect(character.send(:effective_passive_skill_level, :knife_mastery)).to eq(130)
      expect(character.send(:effective_passive_skill_level, :bludgeoning_mastery)).to eq(150)
      expect(character.reload.passive_skills).to eq("knife_mastery" => 100, "bludgeoning_mastery" => 100)

      item.update!(equipped: false, equipment_slot: nil)
      expect(character.passive_skill_level(:knife_mastery)).to eq(100)
      expect(character.passive_skill_level(:bludgeoning_mastery)).to eq(100)
    end

    it "adds equipment once through both readers below the allocation cap" do
      character.update!(passive_skills: {"knife_mastery" => 20})
      template = create(:item_template, stat_modifiers: {"knife_skill" => 5})
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)

      expect(character.passive_skill_level(:knife_mastery)).to eq(25)
      expect(character.send(:effective_passive_skill_level, :knife_mastery)).to eq(25)
    end

    it "accepts flat canonical skills and nested aliases without treating other effects as skills" do
      character.update!(passive_skills: {"extra_action_points" => 100})
      template = create(:item_template, stat_modifiers: {
        "Extra Action Points" => 7, "physical_damage_resistance" => 6,
        "exotic_weapon_mastery" => 5, "wanderer" => 4, "knife_skill" => 3,
        "skill_bonuses" => {"knife_skill" => 2, "extra_action_points" => 1, "invented_skill" => 50},
        "strength" => 20, "crushing" => 90, "invented_skill" => 80
      })
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)

      expect(character.passive_skill_level(:extra_action_points)).to eq(108)
      expect(character.max_action_points).to eq(208)
      expect(character.passive_skill_level(:physical_damage_resistance)).to eq(6)
      expect(character.passive_skill_level(:exotic_weapon_mastery)).to eq(5)
      expect(character.passive_skill_level(:wanderer)).to eq(4)
      expect(character.passive_skill_level(:knife_mastery)).to eq(5)
      expect(character.passive_skill_level(:strength)).to eq(0)
      expect(character.passive_skill_level(:crushing)).to eq(0)
      expect(character.passive_skill_level(:invented_skill)).to eq(0)
    end

    it "ignores broken and carried skill bonuses and applies current instance overrides" do
      template = create(:item_template, :durable, stat_modifiers: {"knife_skill" => 5})
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: template,
        properties: {"effects" => {"knife_skill" => 9}})
      create(:inventory_item, :equipped, :broken, inventory: character.inventory, item_template: template)
      create(:inventory_item, inventory: character.inventory, item_template: template)

      expect(character.passive_skill_level(:knife_mastery)).to eq(9)
    end

    it "caps actual allocation at 100 while preserving the equipment total" do
      character.update!(combat_skill_points: 2, passive_skills: {"knife_mastery" => 98})
      template = create(:item_template, stat_modifiers: {"knife_skill" => 30})
      create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)
      service = Characters::SkillAllocationService.new(character:)

      service.call(allocations: {knife_mastery: 2})

      expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(100)
      expect(character.passive_skill_level(:knife_mastery)).to eq(130)
      expect(character.combat_skill_points).to eq(1)
      expect { service.call(allocations: {knife_mastery: 1}) }
        .to raise_error(Characters::SkillAllocationService::AllocationError, /No allocatable/)
      expect(character.reload.combat_skill_points).to eq(1)
      expect(character.base_passive_skill_level(:knife_mastery)).to eq(100)
    end
  end
end
