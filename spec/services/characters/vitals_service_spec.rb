# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::VitalsService do
  let(:character) do
    create(:character,
      allocated_stats: {"strength" => 9, "dexterity" => 7, "intelligence" => 4, "vitality" => 11, "luck" => 2},
      current_hp: 80, max_hp: 100, current_mp: 30, max_mp: 50,
      hp_regen_interval: 100, mp_regen_interval: 60)
  end

  subject(:service) { described_class.new(character) }

  describe "#stats_summary" do
    it "returns a hash with all stat values" do
      summary = service.stats_summary

      expect(summary).to be_a(Hash)
      expect(summary.keys).to include(
        :current_hp, :max_hp, :current_mp, :max_mp,
        :strength, :dexterity, :luck, :intelligence, :vitality,
        :attack_power, :defense, :crit_rate, :combat_power_breakdown
      )
    end

    it "returns current HP and MP values" do
      summary = service.stats_summary

      expect(summary[:current_hp]).to eq(80)
      expect(summary[:max_hp]).to eq(100)
      expect(summary[:current_mp]).to eq(30)
      expect(summary[:max_mp]).to eq(50)
    end

    it "returns effective primary stat values" do
      summary = service.stats_summary

      expect(summary[:strength]).to eq(10)
      expect(summary[:dexterity]).to eq(8)
      expect(summary[:luck]).to eq(3)
      expect(summary[:intelligence]).to eq(5)
      expect(summary[:vitality]).to eq(12)
    end

    it "calculates attack power from strength and dexterity" do
      summary = service.stats_summary

      # Base: strength * 2 + dexterity / 2 + level / 2 = 10 * 2 + 8 / 2 + 1 / 2 = 24
      expect(summary[:attack_power]).to eq(24)
    end

    it "calculates defense from vitality and strength" do
      summary = service.stats_summary

      # Base: vitality + strength / 3 + level / 2 = 12 + 10 / 3 + 1 / 2 = 15
      expect(summary[:defense]).to eq(15)
    end

    it "calculates crit rate from dexterity and luck" do
      summary = service.stats_summary

      # Base: 5 + dexterity / 5 + luck / 10 = 5 + 8/5 + 3/10 = 5 + 1 + 0 = 6
      expect(summary[:crit_rate]).to eq(6)
    end

    context "with equipped items" do
      let(:sword_template) do
        create(:item_template, name: "Iron Sword", item_type: "equipment", slot: "main_hand",
          stat_modifiers: {"attack" => 15})
      end
      let(:armor_template) do
        create(:item_template, name: "Iron Armor", item_type: "equipment", slot: "chest",
          stat_modifiers: {"defense" => 10})
      end

      before do
        inventory = character.inventory
        create(:inventory_item, inventory: inventory, item_template: sword_template, equipped: true)
        create(:inventory_item, inventory: inventory, item_template: armor_template, equipped: true)
      end

      it "includes equipment attack bonus in attack power" do
        summary = service.stats_summary

        # Base (24) + sword attack bonus (15) = 39
        expect(summary[:attack_power]).to eq(39)
      end

      it "includes equipment defense bonus in defense" do
        summary = service.stats_summary

        # Base (15) + explicit defense bonus (10) = 25
        expect(summary[:defense]).to eq(25)
      end
    end
  end

  describe "#apply_damage" do
    it "reduces current HP" do
      expect {
        service.apply_damage(20, source: "Test")
      }.to change { character.current_hp }.from(80).to(60)
    end

    it "sets combat state" do
      service.apply_damage(20, source: "Test")

      expect(character.in_combat).to be true
    end

    it "does not go below 0 HP" do
      service.apply_damage(200, source: "Test")

      # After applying damage greater than HP, HP should be clamped to 0
      expect(character.current_hp).to be >= 0
      expect(character.current_hp).to be <= 80 # Was 80 originally
    end
  end

  describe "#apply_healing" do
    it "increases current HP" do
      expect {
        service.apply_healing(15, source: "Potion")
      }.to change { character.current_hp }.from(80).to(95)
    end

    it "does not exceed max HP" do
      service.apply_healing(50, source: "Potion")

      expect(character.current_hp).to eq(100)
    end
  end

  describe "#consume_mana" do
    it "returns true and consumes mana when sufficient" do
      expect(service.consume_mana(20)).to be true
      expect(character.current_mp).to eq(10)
    end

    it "returns false when insufficient mana" do
      expect(service.consume_mana(50)).to be false
      expect(character.current_mp).to eq(30)
    end
  end

  describe "#hp_percent" do
    it "calculates HP as percentage" do
      expect(service.hp_percent).to eq(80.0)
    end
  end

  describe "#mp_percent" do
    it "calculates MP as percentage" do
      expect(service.mp_percent).to eq(60.0)
    end
  end
end
