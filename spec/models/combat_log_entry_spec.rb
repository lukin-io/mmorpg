# frozen_string_literal: true

require "rails_helper"

RSpec.describe CombatLogEntry do
  let(:character) { create(:character, :with_position) }
  let(:battle) { create(:battle, initiator: character) }

  describe "associations" do
    it "belongs to battle" do
      entry = create(:combat_log_entry, battle: battle)
      expect(entry.battle).to eq(battle)
    end

    it "belongs to ability (optional)" do
      ability = create(:ability, character_class: character.character_class)
      entry = create(:combat_log_entry, battle: battle, ability: ability)
      expect(entry.ability).to eq(ability)

      # Test optional
      entry_without = create(:combat_log_entry, battle: battle, ability: nil)
      expect(entry_without).to be_valid
    end
  end

  describe "validations" do
    it "requires message" do
      entry = build(:combat_log_entry, battle: battle, message: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:message]).to be_present
    end

    it "accepts valid entry" do
      entry = build(:combat_log_entry, battle: battle, message: "Attack!")
      expect(entry).to be_valid
    end
  end

  describe "default scope" do
    it "orders by round_number and sequence" do
      entry3 = create(:combat_log_entry, battle: battle, round_number: 2, sequence: 1, message: "Third")
      entry1 = create(:combat_log_entry, battle: battle, round_number: 1, sequence: 1, message: "First")
      entry2 = create(:combat_log_entry, battle: battle, round_number: 1, sequence: 2, message: "Second")

      entries = battle.combat_log_entries.to_a
      expect(entries).to eq([entry1, entry2, entry3])
    end
  end

  describe "scopes" do
    describe ".damage" do
      it "returns entries with damage" do
        damage_entry = create(:combat_log_entry, battle: battle, damage_amount: 50, message: "Attack")
        create(:combat_log_entry, battle: battle, damage_amount: 0, message: "Buff")

        expect(described_class.damage).to include(damage_entry)
        expect(described_class.damage.count).to eq(1)
      end
    end

    describe ".healing" do
      it "returns entries with healing" do
        healing_entry = create(:combat_log_entry, battle: battle, healing_amount: 30, message: "Heal")
        create(:combat_log_entry, battle: battle, healing_amount: 0, message: "Attack")

        expect(described_class.healing).to include(healing_entry)
        expect(described_class.healing.count).to eq(1)
      end
    end

    describe ".by_actor" do
      it "filters by actor_id" do
        actor_entry = create(:combat_log_entry, battle: battle, actor_id: character.id, message: "Actor action")
        create(:combat_log_entry, battle: battle, actor_id: nil, message: "No actor")

        expect(described_class.by_actor(character.id)).to include(actor_entry)
        expect(described_class.by_actor(character.id).count).to eq(1)
      end

      it "returns all when actor_id is nil" do
        create(:combat_log_entry, battle: battle, message: "Entry 1")
        create(:combat_log_entry, battle: battle, message: "Entry 2")

        expect(described_class.by_actor(nil).count).to eq(2)
      end
    end
  end

  describe "payload storage" do
    it "stores structured payload data" do
      entry = create(:combat_log_entry,
        battle: battle,
        message: "Attack landed",
        payload: {
          "attacker" => "Hero",
          "defender" => "Goblin",
          "damage" => 25,
          "critical" => true,
          "effects" => [{"type" => "bleed", "duration" => 3}]
        })

      entry.reload
      expect(entry.payload["attacker"]).to eq("Hero")
      expect(entry.payload["critical"]).to be true
      expect(entry.payload["effects"]).to be_an(Array)
    end
  end

  describe "log types" do
    it "stores log type" do
      entry = create(:combat_log_entry, battle: battle, log_type: "skill", message: "Fireball cast")
      expect(entry.log_type).to eq("skill")
    end

    it "can distinguish action types" do
      attack = create(:combat_log_entry, battle: battle, log_type: "attack", message: "Attack")
      skill = create(:combat_log_entry, battle: battle, log_type: "skill", message: "Skill")
      heal = create(:combat_log_entry, battle: battle, log_type: "heal", message: "Heal")

      expect(attack.log_type).to eq("attack")
      expect(skill.log_type).to eq("skill")
      expect(heal.log_type).to eq("heal")
    end
  end

  describe "round and sequence tracking" do
    it "tracks combat progression accurately" do
      # Round 1
      create(:combat_log_entry, battle: battle, round_number: 1, sequence: 1, message: "Player attacks")
      create(:combat_log_entry, battle: battle, round_number: 1, sequence: 2, message: "Enemy counters")

      # Round 2
      create(:combat_log_entry, battle: battle, round_number: 2, sequence: 1, message: "Player defends")
      create(:combat_log_entry, battle: battle, round_number: 2, sequence: 2, message: "Enemy attacks")

      entries = battle.combat_log_entries.to_a
      expect(entries.map(&:round_number)).to eq([1, 1, 2, 2])
      expect(entries.map(&:sequence)).to eq([1, 2, 1, 2])
    end
  end

  describe "damage and healing amounts" do
    it "tracks damage amount" do
      entry = create(:combat_log_entry, battle: battle, damage_amount: 50, message: "Critical hit!")
      expect(entry.damage_amount).to eq(50)
    end

    it "tracks healing amount" do
      entry = create(:combat_log_entry, battle: battle, healing_amount: 30, message: "Healed!")
      expect(entry.healing_amount).to eq(30)
    end

    it "defaults amounts to 0" do
      entry = create(:combat_log_entry, battle: battle, message: "Buff applied")
      expect(entry.damage_amount).to eq(0).or be_nil
      expect(entry.healing_amount).to eq(0).or be_nil
    end
  end
end
