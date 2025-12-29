# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::TurnResolver do
  let(:zone) { create(:zone) }
  let(:character) { create(:character, :with_position, current_hp: 100, max_hp: 100) }
  let(:enemy_character) { create(:character, :with_position, current_hp: 100, max_hp: 100) }

  let(:battle) do
    create(:battle, battle_type: :pvp, initiator: character, zone: zone, pvp_mode: "duel")
  end

  let!(:attacker_participant) do
    create(:battle_participant,
      battle: battle,
      character: character,
      team: "alpha",
      initiative: 15,
      current_hp: 100,
      max_hp: 100,
      is_alive: true,
      pending_attacks: [{"body_part" => "torso", "attack_type" => "simple"}]
    )
  end

  let!(:defender_participant) do
    create(:battle_participant,
      battle: battle,
      character: enemy_character,
      team: "beta",
      initiative: 5,
      current_hp: 100,
      max_hp: 100,
      is_alive: true,
      pending_blocks: []
    )
  end

  describe "#resolve!" do
    it "produces deterministic results with seeded RNG" do
      resolver = described_class.new(battle, rng: Random.new(123))
      result = resolver.resolve!

      expect(result).to be_a(described_class::Result)
      expect(result.success).to be true
      expect(result.log_entries).to be_an(Array)
    end

    it "processes attacks and updates HP" do
      resolver = described_class.new(battle, rng: Random.new(456))
      result = resolver.resolve!

      expect(result.hp_changes).to be_present
      expect(result.log_entries.any? { |e| e[:message].present? }).to be true
    end

    it "advances turn number on completion" do
      initial_turn = battle.turn_number

      resolver = described_class.new(battle, rng: Random.new(789))
      resolver.resolve!

      expect(battle.reload.turn_number).to be > initial_turn
    end

    it "provides legacy log accessor" do
      resolver = described_class.new(battle, rng: Random.new(100))
      result = resolver.resolve!

      # The Result should have #log alias for compatibility
      expect(result).to respond_to(:log)
      expect(result.log).to be_an(Array)
    end
  end

  context "with ability effects" do
    let(:ability) do
      create(
        :ability,
        character_class: character.character_class,
        effects: {
          "status" => "shield",
          "buffs" => [{"name" => "Fury", "duration" => 2, "stat_changes" => {"attack" => 3}}],
          "debuffs" => [{"name" => "Expose", "duration" => 2, "stat_changes" => {"defense" => -2}}],
          "damage" => 5
        }
      )
    end

    before do
      # Set up skill usage
      attacker_participant.update!(
        pending_attacks: [],
        pending_skills: [{"skill_key" => ability.name, "target_id" => enemy_character.id}]
      )
    end

    it "applies effects from abilities" do
      resolver = described_class.new(battle, rng: Random.new(200))
      result = resolver.resolve!

      expect(result.success).to be true
      expect(result.effects_applied).to be_an(Array)
    end
  end

  context "when battle is not active" do
    before do
      battle.update!(status: :completed)
    end

    it "returns failure result" do
      resolver = described_class.new(battle, rng: Random.new(300))
      result = resolver.resolve!

      expect(result.success).to be false
      expect(result.errors).to include(/not active/i)
    end
  end
end
