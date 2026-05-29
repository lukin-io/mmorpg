# frozen_string_literal: true

require "rails_helper"

RSpec.describe CombatLogEntry do
  let(:character) { create(:character, :with_position) }
  let(:arena_match) { create(:arena_match, :live) }

  describe "associations" do
    it "allows entries without actor metadata" do
      entry = create(:combat_log_entry, arena_match: arena_match, actor_id: nil, actor_type: nil)
      expect(entry).to be_valid
    end

    it "belongs to an arena match" do
      entry = create(:combat_log_entry, arena_match: arena_match)
      expect(entry.arena_match).to eq(arena_match)
    end
  end

  describe "validations" do
    it "requires message" do
      entry = build(:combat_log_entry, arena_match: arena_match, message: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:message]).to be_present
    end

    it "accepts valid entry" do
      entry = build(:combat_log_entry, arena_match: arena_match, message: "Attack!")
      expect(entry).to be_valid
    end

    it "requires an arena match" do
      entry = build(:combat_log_entry, arena_match: nil)
      expect(entry).not_to be_valid
    end

    it "sets occurrence time" do
      entry = create(:combat_log_entry, arena_match: arena_match)
      expect(entry.occurred_at).to be_present
    end
  end

  describe "default scope" do
    it "orders by round_number and sequence" do
      entry3 = create(:combat_log_entry, arena_match: arena_match, round_number: 2, sequence: 1, message: "Third")
      entry1 = create(:combat_log_entry, arena_match: arena_match, round_number: 1, sequence: 1, message: "First")
      entry2 = create(:combat_log_entry, arena_match: arena_match, round_number: 1, sequence: 2, message: "Second")

      entries = arena_match.combat_log_entries.to_a
      expect(entries).to eq([entry1, entry2, entry3])
    end
  end

  describe "scopes" do
    describe ".damage" do
      it "returns entries with damage" do
        damage_entry = create(:combat_log_entry, arena_match: arena_match, damage_amount: 50, message: "Attack")
        create(:combat_log_entry, arena_match: arena_match, damage_amount: 0, message: "Block")

        expect(described_class.damage).to include(damage_entry)
        expect(described_class.damage.count).to eq(1)
      end
    end

    describe ".by_actor" do
      it "filters by actor_id" do
        actor_entry = create(:combat_log_entry, arena_match: arena_match, actor_id: character.id, message: "Actor action")
        create(:combat_log_entry, arena_match: arena_match, actor_id: nil, message: "No actor")

        expect(described_class.by_actor(character.id)).to include(actor_entry)
        expect(described_class.by_actor(character.id).count).to eq(1)
      end

      it "returns all when actor_id is nil" do
        create(:combat_log_entry, arena_match: arena_match, message: "Entry 1")
        create(:combat_log_entry, arena_match: arena_match, message: "Entry 2")

        expect(described_class.by_actor(nil).count).to eq(2)
      end
    end
  end

  describe "payload storage" do
    it "stores structured payload data" do
      entry = create(:combat_log_entry,
        arena_match: arena_match,
        message: "max_kerby hit Plague Rat (torso) for -3 [7/10]",
        payload: {
          "attacker" => "max_kerby",
          "defender" => "Plague Rat",
          "damage" => 25,
          "body_part" => "torso",
          "outcome" => "damage"
        })

      entry.reload
      expect(entry.payload["attacker"]).to eq("max_kerby")
      expect(entry.payload["body_part"]).to eq("torso")
      expect(entry.payload["outcome"]).to eq("damage")
    end
  end

  describe "log types" do
    it "stores log type" do
      entry = create(:combat_log_entry, arena_match: arena_match, log_type: "block", message: "max_kerby blocks head")
      expect(entry.log_type).to eq("block")
    end

    it "can distinguish captured fight action types" do
      attack = create(:combat_log_entry, arena_match: arena_match, log_type: "attack", message: "Attack")
      block = create(:combat_log_entry, arena_match: arena_match, log_type: "block", message: "Block")
      loot = create(:combat_log_entry, arena_match: arena_match, log_type: "loot", message: "Rat Tail")

      expect(attack.log_type).to eq("attack")
      expect(block.log_type).to eq("block")
      expect(loot.log_type).to eq("loot")
    end
  end

  describe "round and sequence tracking" do
    it "tracks combat progression accurately" do
      # Round 1
      create(:combat_log_entry, arena_match: arena_match, round_number: 1, sequence: 1, message: "Player attacks")
      create(:combat_log_entry, arena_match: arena_match, round_number: 1, sequence: 2, message: "Enemy counters")

      # Round 2
      create(:combat_log_entry, arena_match: arena_match, round_number: 2, sequence: 1, message: "Player defends")
      create(:combat_log_entry, arena_match: arena_match, round_number: 2, sequence: 2, message: "Enemy attacks")

      entries = arena_match.combat_log_entries.to_a
      expect(entries.map(&:round_number)).to eq([1, 1, 2, 2])
      expect(entries.map(&:sequence)).to eq([1, 2, 1, 2])
    end
  end

  describe "damage amounts" do
    it "tracks damage amount" do
      entry = create(:combat_log_entry, arena_match: arena_match, damage_amount: 50, message: "Critical hit!")
      expect(entry.damage_amount).to eq(50)
    end

    it "defaults damage amount to 0" do
      entry = create(:combat_log_entry, arena_match: arena_match, message: "Block")
      expect(entry.damage_amount).to eq(0).or be_nil
    end
  end
end
