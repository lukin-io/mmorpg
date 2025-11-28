# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::SkillExecutor do
  let(:character) { create(:character, :with_position) }
  let(:battle) { create(:battle, initiator: character) }
  let!(:player_participant) { create(:battle_participant, battle: battle, character: character, team: "player") }
  let(:npc_template) { create(:npc_template, name: "Target", level: 3) }
  let!(:enemy_participant) { create(:battle_participant, battle: battle, npc_template: npc_template, character: nil, team: "enemy", current_hp: 100, max_hp: 100) }

  # Simple target that works with the skill executor
  let(:target) do
    target = OpenStruct.new(
      id: enemy_participant.id,
      name: "Target",
      current_hp: 100,
      max_hp: 100
    )
    target.define_singleton_method(:current_hp=) { |v| @current_hp = v }
    target.define_singleton_method(:save!) { true }
    target
  end

  describe ".available_skills" do
    context "with class abilities" do
      let(:ability) do
        create(:ability,
          character_class: character.character_class,
          name: "Fireball",
          kind: "active",
          effects: {"type" => "damage", "base_damage" => 50},
          resource_cost: {"mp" => 20},
          cooldown_seconds: 5)
      end

      before { ability }

      it "returns class abilities" do
        skills = described_class.available_skills(character)

        fireball = skills.find { |s| s[:name] == "Fireball" }
        expect(fireball).to be_present
        expect(fireball[:source]).to eq(:ability)
        expect(fireball[:cost]).to eq({"mp" => 20})
      end
    end

    context "with skill tree nodes" do
      let(:skill_tree) { create(:skill_tree, character_class: character.character_class) }
      let(:skill_node) do
        create(:skill_node,
          skill_tree: skill_tree,
          name: "Power Strike",
          node_type: "active",
          effects: {"type" => "damage", "base_damage" => 30},
          resource_cost: {"mp" => 10},
          cooldown_seconds: 3)
      end

      before do
        # Associate skill node with character using the join table
        CharacterSkill.create!(
          character: character,
          skill_node: skill_node,
          unlocked_at: Time.current
        )
      end

      it "returns unlocked skill nodes" do
        skills = described_class.available_skills(character)

        power_strike = skills.find { |s| s[:name] == "Power Strike" }
        expect(power_strike).to be_present
        expect(power_strike[:source]).to eq(:skill_node)
        expect(power_strike[:type]).to eq("damage")
      end
    end

    it "returns empty array for character without skills" do
      skills = described_class.available_skills(character)
      expect(skills).to be_an(Array)
    end
  end

  describe "#execute!" do
    describe "damage skill" do
      let(:damage_skill) do
        OpenStruct.new(
          id: 1,
          name: "Slash",
          effects: {"type" => "damage", "base_damage" => 30, "scaling_stat" => "strength", "scaling_factor" => 0.5},
          resource_cost: {},
          cooldown_seconds: 0
        )
      end

      let(:executor) do
        described_class.new(
          caster: character,
          target: target,
          skill: damage_skill,
          battle: battle
        )
      end

      it "deals damage to target" do
        result = executor.execute!

        expect(result.success).to be true
        expect(result.damage).to be > 0
      end

      it "creates combat log entry" do
        expect { executor.execute! }.to change(CombatLogEntry, :count).by(1)
      end

      it "returns result with damage info" do
        result = executor.execute!

        expect(result.message).to include(damage_skill.name)
        expect(result.message).to include("damage")
      end
    end

    describe "heal skill" do
      let(:heal_skill) do
        OpenStruct.new(
          id: 2,
          name: "Healing Light",
          effects: {"type" => "heal", "base_heal" => 40, "scaling_stat" => "spirit", "scaling_factor" => 0.6},
          resource_cost: {},
          cooldown_seconds: 0
        )
      end

      let(:heal_target) do
        t = OpenStruct.new(
          id: player_participant.id,
          name: character.name,
          current_hp: 50,
          max_hp: 100
        )
        t.define_singleton_method(:current_hp=) { |v| @current_hp = v }
        t.define_singleton_method(:save!) { true }
        t
      end

      let(:executor) do
        described_class.new(
          caster: character,
          target: heal_target,
          skill: heal_skill,
          battle: battle
        )
      end

      it "returns success for heal" do
        result = executor.execute!

        expect(result.success).to be true
        expect(result.healing).to be > 0
      end

      it "returns healing message" do
        result = executor.execute!
        expect(result.message).to include("healing")
      end
    end

    describe "buff skill" do
      let(:buff_skill) do
        OpenStruct.new(
          id: 3,
          name: "Battle Cry",
          effects: {"type" => "buff", "buff_stat" => "strength", "buff_value" => 10, "duration" => 3},
          resource_cost: {},
          cooldown_seconds: 0
        )
      end

      let(:executor) do
        described_class.new(
          caster: character,
          target: nil, # Self buff
          skill: buff_skill,
          battle: battle
        )
      end

      it "applies buff effect" do
        result = executor.execute!

        expect(result.success).to be true
        expect(result.effects_applied).to include(hash_including(type: "buff"))
      end

      it "specifies buff details" do
        result = executor.execute!
        buff = result.effects_applied.find { |e| e[:type] == "buff" }

        expect(buff[:stat]).to eq("strength")
        expect(buff[:value]).to eq(10)
        expect(buff[:duration]).to eq(3)
      end
    end

    describe "DOT skill" do
      let(:dot_skill) do
        OpenStruct.new(
          id: 5,
          name: "Poison",
          effects: {"type" => "dot", "tick_damage" => 15, "duration" => 3},
          resource_cost: {},
          cooldown_seconds: 0
        )
      end

      let(:executor) do
        described_class.new(
          caster: character,
          target: target,
          skill: dot_skill,
          battle: battle
        )
      end

      it "applies DOT effect" do
        result = executor.execute!

        expect(result.success).to be true
        expect(result.effects_applied).to include(hash_including(type: "dot"))
      end

      it "specifies DOT details" do
        result = executor.execute!
        dot = result.effects_applied.find { |e| e[:type] == "dot" }

        expect(dot[:damage]).to eq(15)
        expect(dot[:duration]).to eq(3)
      end
    end

    describe "AOE skill" do
      let(:aoe_skill) do
        OpenStruct.new(
          id: 7,
          name: "Whirlwind",
          effects: {"type" => "aoe", "base_damage" => 20, "radius" => 1},
          resource_cost: {},
          cooldown_seconds: 0
        )
      end

      let(:executor) do
        described_class.new(
          caster: character,
          target: target,
          skill: aoe_skill,
          battle: battle
        )
      end

      it "deals AOE damage" do
        result = executor.execute!

        expect(result.success).to be true
        expect(result.damage).to be > 0
        expect(result.effects_applied).to include(hash_including(type: "aoe"))
      end
    end

    describe "drain skill" do
      let(:drain_skill) do
        OpenStruct.new(
          id: 8,
          name: "Life Drain",
          effects: {"type" => "drain", "base_damage" => 25, "drain_percent" => 50},
          resource_cost: {},
          cooldown_seconds: 0
        )
      end

      # Caster needs HP tracking for drain
      let(:draining_caster) do
        c = OpenStruct.new(
          id: character.id,
          name: character.name,
          current_hp: 50,
          max_hp: 100,
          stats: nil
        )
        c.define_singleton_method(:current_hp=) { |v| @current_hp = v }
        c.define_singleton_method(:save!) { true }
        c
      end

      let(:executor) do
        described_class.new(
          caster: draining_caster,
          target: target,
          skill: drain_skill,
          battle: battle
        )
      end

      it "deals damage and heals caster" do
        result = executor.execute!

        expect(result.success).to be true
        expect(result.damage).to be > 0
        expect(result.healing).to be > 0
        expect(result.effects_applied).to include(hash_including(type: "drain"))
      end
    end

    describe "shield skill" do
      let(:shield_skill) do
        OpenStruct.new(
          id: 9,
          name: "Barrier",
          effects: {"type" => "shield", "shield_amount" => 50, "duration" => 3},
          resource_cost: {},
          cooldown_seconds: 0
        )
      end

      let(:executor) do
        described_class.new(
          caster: character,
          target: nil, # Self
          skill: shield_skill,
          battle: battle
        )
      end

      it "applies shield effect" do
        result = executor.execute!

        expect(result.success).to be true
        expect(result.effects_applied).to include(hash_including(type: "shield"))
      end

      it "specifies shield details" do
        result = executor.execute!
        shield = result.effects_applied.find { |e| e[:type] == "shield" }

        expect(shield[:amount]).to eq(50)
        expect(shield[:duration]).to eq(3)
      end
    end

    describe "resource consumption" do
      let(:mp_skill) do
        OpenStruct.new(
          id: 10,
          name: "Expensive Spell",
          effects: {"type" => "damage", "base_damage" => 100},
          resource_cost: {"mp" => 30},
          cooldown_seconds: 0
        )
      end

      context "with insufficient resources" do
        let(:low_mp_caster) do
          c = OpenStruct.new(
            id: character.id,
            name: character.name,
            current_hp: 100,
            current_mp: 10
          )
          c
        end

        let(:executor) do
          described_class.new(
            caster: low_mp_caster,
            target: target,
            skill: mp_skill,
            battle: battle
          )
        end

        it "returns failure" do
          result = executor.execute!

          expect(result.success).to be false
          expect(result.message).to include("Not enough resources")
        end
      end
    end

    describe "cooldown handling" do
      let(:cooldown_skill) do
        OpenStruct.new(
          id: 11,
          name: "Ultimate",
          effects: {"type" => "damage", "base_damage" => 200},
          resource_cost: {},
          cooldown_seconds: 60
        )
      end

      let(:executor) do
        described_class.new(
          caster: character,
          target: target,
          skill: cooldown_skill,
          battle: battle
        )
      end

      it "sets cooldown after use" do
        executor.execute!
        battle.reload

        cooldown_key = "skill_#{cooldown_skill.id}_cooldown"
        expect(battle.metadata.dig("cooldowns", cooldown_key)).to be_present
      end

      it "prevents use while on cooldown" do
        # First use
        executor.execute!

        # Immediately try again
        second_result = executor.execute!
        expect(second_result.success).to be false
        expect(second_result.message).to include("cooldown")
      end
    end

    describe "validation failures" do
      context "without skill" do
        let(:executor) do
          described_class.new(
            caster: character,
            target: target,
            skill: nil,
            battle: battle
          )
        end

        it "returns failure" do
          result = executor.execute!
          expect(result.success).to be false
          expect(result.message).to include("No skill")
        end
      end

      context "with dead caster" do
        let(:skill) do
          OpenStruct.new(
            id: 12,
            name: "Test",
            effects: {"type" => "damage"},
            resource_cost: {},
            cooldown_seconds: 0
          )
        end

        let(:dead_caster) do
          OpenStruct.new(
            id: character.id,
            name: character.name,
            current_hp: 0
          )
        end

        let(:executor) do
          described_class.new(
            caster: dead_caster,
            target: target,
            skill: skill,
            battle: battle
          )
        end

        it "returns failure" do
          result = executor.execute!
          expect(result.success).to be false
          expect(result.message).to include("dead")
        end
      end
    end
  end

  describe "Result struct" do
    it "has expected attributes" do
      result = described_class::Result.new(
        success: true,
        damage: 50,
        healing: 0,
        effects_applied: [],
        message: "Test",
        critical: false
      )

      expect(result.success).to be true
      expect(result.damage).to eq(50)
      expect(result.healing).to eq(0)
      expect(result.effects_applied).to eq([])
      expect(result.message).to eq("Test")
      expect(result.critical).to be false
    end
  end
end
