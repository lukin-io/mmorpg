# frozen_string_literal: true

require "rails_helper"

RSpec.describe BattleParticipant do
  let(:character) { create(:character, :with_position) }
  let(:battle) { create(:battle, initiator: character) }

  describe "associations" do
    it "belongs to battle" do
      participant = create(:battle_participant, battle: battle, character: character)
      expect(participant.battle).to eq(battle)
    end

    it "belongs to character (optional)" do
      participant = create(:battle_participant, battle: battle, character: character)
      expect(participant.character).to eq(character)

      # Test optional
      npc = create(:npc_template)
      participant_npc = create(:battle_participant, battle: battle, character: nil, npc_template: npc)
      expect(participant_npc).to be_valid
    end

    it "belongs to npc_template (optional)" do
      npc = create(:npc_template)
      participant = create(:battle_participant, battle: battle, npc_template: npc, character: nil)
      expect(participant.npc_template).to eq(npc)

      # Test optional
      participant_char = create(:battle_participant, battle: battle, character: character, npc_template: nil)
      expect(participant_char).to be_valid
    end
  end

  describe "validations" do
    it "requires role" do
      participant = build(:battle_participant, battle: battle, character: character, role: nil)
      expect(participant).not_to be_valid
      expect(participant.errors[:role]).to be_present
    end

    it "requires team" do
      participant = build(:battle_participant, battle: battle, character: character, team: nil)
      expect(participant).not_to be_valid
      expect(participant.errors[:team]).to be_present
    end

    it "requires hp_remaining to be >= 0" do
      participant = build(:battle_participant, battle: battle, character: character, hp_remaining: -1)
      expect(participant).not_to be_valid
      expect(participant.errors[:hp_remaining]).to be_present
    end

    it "requires initiative to be >= 0" do
      participant = build(:battle_participant, battle: battle, character: character, initiative: -1)
      expect(participant).not_to be_valid
      expect(participant.errors[:initiative]).to be_present
    end
  end

  describe "defaults" do
    it "defaults is_alive to true" do
      participant = described_class.new
      expect(participant.is_alive).to be true
    end

    it "defaults current_hp to 100" do
      participant = described_class.new
      expect(participant.current_hp).to eq(100)
    end

    it "defaults current_mp to 50" do
      participant = described_class.new
      expect(participant.current_mp).to eq(50)
    end
  end

  describe "#combatant_name" do
    context "with character participant" do
      it "returns character name" do
        char = create(:character, name: "TestHero")
        participant = create(:battle_participant, battle: battle, character: char, npc_template: nil)
        expect(participant.combatant_name).to eq("TestHero")
      end
    end

    context "with NPC participant" do
      it "returns NPC name" do
        npc = create(:npc_template, name: "Goblin")
        participant = create(:battle_participant, battle: battle, character: nil, npc_template: npc)
        expect(participant.combatant_name).to eq("Goblin")
      end
    end

    context "with neither character nor NPC" do
      it "returns 'Unknown'" do
        participant = build(:battle_participant, battle: battle, character: nil, npc_template: nil)
        expect(participant.combatant_name).to eq("Unknown")
      end
    end
  end

  describe "combat tracking attributes" do
    let(:participant) { create(:battle_participant, battle: battle, character: character) }

    describe "damage tracking" do
      it "tracks damage dealt by type" do
        participant.damage_dealt = {"normal" => 50, "fire" => 25, "total" => 75}
        participant.save!
        participant.reload

        expect(participant.damage_dealt["normal"]).to eq(50)
        expect(participant.damage_dealt["fire"]).to eq(25)
        expect(participant.damage_dealt["total"]).to eq(75)
      end

      it "tracks damage received by type" do
        participant.damage_received = {"normal" => 30, "total" => 30}
        participant.save!
        participant.reload

        expect(participant.damage_received["normal"]).to eq(30)
      end
    end

    describe "body damage tracking" do
      it "tracks damage to body parts" do
        participant.body_damage = {"head" => 10, "torso" => 20, "stomach" => 5, "legs" => 15}
        participant.save!
        participant.reload

        expect(participant.body_damage["head"]).to eq(10)
        expect(participant.body_damage["torso"]).to eq(20)
      end
    end

    describe "combat buffs" do
      it "stores combat buff effects" do
        participant.combat_buffs = [
          {"type" => "buff", "data" => {"stat" => "strength", "value" => 10}, "duration" => 3}
        ]
        participant.save!
        participant.reload

        expect(participant.combat_buffs.first["type"]).to eq("buff")
      end
    end

    describe "pending actions" do
      it "tracks pending attacks" do
        participant.pending_attacks = [{"target" => "head", "cost" => 0}]
        participant.save!
        expect(participant.pending_attacks.first["target"]).to eq("head")
      end

      it "tracks pending blocks" do
        participant.pending_blocks = [{"zone" => "torso", "cost" => 0}]
        participant.save!
        expect(participant.pending_blocks.first["zone"]).to eq("torso")
      end

      it "tracks pending skills" do
        participant.pending_skills = [{"skill_id" => 1, "target_id" => 2}]
        participant.save!
        expect(participant.pending_skills.first["skill_id"]).to eq(1)
      end
    end
  end

  describe "HP and MP management" do
    let(:participant) { create(:battle_participant, battle: battle, character: character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50) }

    it "can reduce HP" do
      participant.current_hp -= 30
      participant.save!
      expect(participant.current_hp).to eq(70)
    end

    it "can reduce MP" do
      participant.current_mp -= 20
      participant.save!
      expect(participant.current_mp).to eq(30)
    end

    it "can track is_alive status" do
      participant.current_hp = 0
      participant.is_alive = false
      participant.save!

      expect(participant.is_alive).to be false
    end
  end

  describe "team assignment" do
    it "can be on player team" do
      participant = create(:battle_participant, battle: battle, character: character, team: "player")
      expect(participant.team).to eq("player")
    end

    it "can be on enemy team" do
      participant = create(:battle_participant, battle: battle, character: character, team: "enemy")
      expect(participant.team).to eq("enemy")
    end

    it "can be on alpha team (pvp)" do
      participant = create(:battle_participant, battle: battle, character: character, team: "alpha")
      expect(participant.team).to eq("alpha")
    end

    it "can be on bravo team (pvp)" do
      participant = create(:battle_participant, battle: battle, character: character, team: "bravo")
      expect(participant.team).to eq("bravo")
    end
  end

  describe "stat snapshot" do
    let(:participant) { create(:battle_participant, battle: battle, character: character) }

    it "stores stat snapshot at battle start" do
      participant.stat_snapshot = {"hp" => 100, "attack" => 15, "defense" => 10, "agility" => 12}
      participant.save!
      participant.reload

      expect(participant.stat_snapshot["attack"]).to eq(15)
      expect(participant.stat_snapshot["defense"]).to eq(10)
    end
  end

  describe "action points" do
    let(:participant) { create(:battle_participant, battle: battle, character: character, action_points_used: 0) }

    it "tracks action points used per turn" do
      participant.action_points_used = 40
      participant.save!
      expect(participant.action_points_used).to eq(40)
    end
  end

  describe "fatigue" do
    let(:participant) { create(:battle_participant, battle: battle, character: character, fatigue: 100.0) }

    it "tracks fatigue level" do
      participant.fatigue = 85.5
      participant.save!
      participant.reload
      expect(participant.fatigue.to_f).to be_within(0.01).of(85.5)
    end
  end

  describe "combat statistics" do
    let(:participant) { create(:battle_participant, battle: battle, character: character, hits_landed: 0, hits_blocked: 0, mana_used: 0) }

    it "tracks hits landed" do
      participant.hits_landed = 5
      participant.save!
      expect(participant.hits_landed).to eq(5)
    end

    it "tracks hits blocked" do
      participant.hits_blocked = 3
      participant.save!
      expect(participant.hits_blocked).to eq(3)
    end

    it "tracks mana used" do
      participant.mana_used = 75
      participant.save!
      expect(participant.mana_used).to eq(75)
    end
  end
end
