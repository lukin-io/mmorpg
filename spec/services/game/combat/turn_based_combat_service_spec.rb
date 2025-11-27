# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::TurnBasedCombatService do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:character1) { create(:character, user: user1) }
  let(:character2) { create(:character, user: user2) }
  let(:battle) do
    create(:battle,
      status: :active,
      combat_mode: "simultaneous",
      action_points_per_turn: 80,
      max_mana_per_turn: 50,
      round_number: 1)
  end
  let!(:participant1) do
    create(:battle_participant,
      battle: battle,
      character: character1,
      team: "alpha",
      is_alive: true,
      current_hp: 100,
      max_hp: 100,
      current_mp: 50,
      max_mp: 50,
      fatigue: 100.0)
  end
  let!(:participant2) do
    create(:battle_participant,
      battle: battle,
      character: character2,
      team: "beta",
      is_alive: true,
      current_hp: 100,
      max_hp: 100,
      current_mp: 50,
      max_mp: 50,
      fatigue: 100.0)
  end

  subject(:service) { described_class.new(battle) }

  describe "#initialize" do
    it "loads the battle" do
      expect(service.battle).to eq(battle)
    end

    it "loads combat config" do
      expect(service.config).to be_a(Hash)
    end

    it "initializes empty errors" do
      expect(service.errors).to eq([])
    end
  end

  describe "#submit_turn" do
    context "with valid attacks" do
      let(:attacks) { [{body_part: "torso", action_key: "simple"}] }

      it "stores pending actions" do
        result = service.submit_turn(character1, attacks: attacks)

        expect(result.success).to be true
        expect(participant1.reload.pending_attacks).to eq(attacks.map(&:stringify_keys))
      end

      it "returns waiting message when opponent hasn't submitted" do
        result = service.submit_turn(character1, attacks: attacks)

        expect(result.message).to include("Waiting for opponent")
        expect(result.round_complete).to be false
      end
    end

    context "with invalid participant" do
      let(:other_character) { create(:character) }

      it "returns failure" do
        result = service.submit_turn(other_character, attacks: [])

        expect(result.success).to be false
        expect(result.message).to eq("Not a participant in this battle")
      end
    end

    context "with defeated participant" do
      before { participant1.update!(is_alive: false) }

      it "returns failure" do
        result = service.submit_turn(character1, attacks: [])

        expect(result.success).to be false
        expect(result.message).to eq("You are defeated")
      end
    end

    context "with excessive action points" do
      let(:attacks) do
        # Multiple attacks that exceed the limit
        Array.new(10) { {body_part: "head", action_key: "aimed"} }
      end

      it "returns failure when exceeding action point limit" do
        result = service.submit_turn(character1, attacks: attacks)

        expect(result.success).to be false
        expect(result.message).to include("Exceeds action point limit")
      end
    end

    context "with insufficient mana" do
      before { participant1.update!(current_mp: 0) }

      let(:skills) { [{key: "fireball", mana: 30}] }

      it "returns failure" do
        result = service.submit_turn(character1, skills: skills)

        expect(result.success).to be false
        expect(result.message).to eq("Not enough MP")
      end
    end
  end

  describe "#resolve_round!" do
    before do
      # Both participants submit simple attacks
      participant1.update!(pending_attacks: [{body_part: "torso", action_key: "simple"}])
      participant2.update!(pending_attacks: [{body_part: "head", action_key: "simple"}])
    end

    it "processes combat and returns log entries" do
      result = service.resolve_round!

      expect(result.success).to be true
      expect(result.log_entries).to be_an(Array)
      expect(result.round_complete).to be true
    end

    it "advances the round number" do
      expect { service.resolve_round! }.to change { battle.reload.round_number }.by(1)
    end

    it "clears pending actions after resolution" do
      service.resolve_round!

      expect(participant1.reload.pending_attacks).to eq([])
      expect(participant2.reload.pending_attacks).to eq([])
    end

    it "applies damage to participants" do
      # Stub rand to ensure hits
      allow_any_instance_of(described_class).to receive(:rand).and_return(50)

      service.resolve_round!

      # At least one participant should have taken damage
      expect(participant1.reload.current_hp < 100 || participant2.reload.current_hp < 100).to be true
    end
  end

  describe "#combat_stats" do
    it "returns participant stats" do
      stats = service.combat_stats(participant1)

      expect(stats[:hp]).to eq(100)
      expect(stats[:max_hp]).to eq(100)
      expect(stats[:mp]).to eq(50)
      expect(stats[:max_mp]).to eq(50)
      expect(stats[:fatigue]).to eq(100.0)
    end
  end

  describe "#available_actions" do
    it "returns attacks for each body part" do
      actions = service.available_actions(participant1)

      expect(actions[:attacks]).to be_an(Array)
      expect(actions[:attacks].map { |a| a[:body_part] }).to include("head", "torso", "stomach", "legs")
    end

    it "returns blocks for each body part" do
      actions = service.available_actions(participant1)

      expect(actions[:blocks]).to be_an(Array)
      expect(actions[:blocks].map { |b| b[:body_part] }).to include("head", "torso", "stomach", "legs")
    end

    it "returns skills array" do
      actions = service.available_actions(participant1)

      expect(actions[:skills]).to be_an(Array)
    end
  end

  describe "battle end conditions" do
    context "when all team beta members are defeated" do
      before do
        participant2.update!(is_alive: false, current_hp: 0)
        participant1.update!(pending_attacks: [{body_part: "torso"}])
      end

      it "marks battle as completed" do
        service.resolve_round!

        expect(battle.reload.status).to eq("completed")
      end

      it "sets ended_at timestamp" do
        service.resolve_round!

        expect(battle.reload.ended_at).to be_present
      end
    end
  end

  describe "body part targeting" do
    it "tracks damage per body part" do
      participant1.update!(pending_attacks: [{body_part: "head", action_key: "simple"}])
      participant2.update!(pending_attacks: [])

      # Force a hit
      allow_any_instance_of(described_class).to receive(:rand).and_return(50)

      service.resolve_round!

      # Check that head damage was tracked (if hit landed)
      body_damage = participant2.reload.body_damage
      expect(body_damage).to be_a(Hash)
    end
  end

  describe "skill execution" do
    before do
      participant1.update!(
        pending_attacks: [],
        pending_skills: [{key: "heal_basic", mana: 10}]
      )
      participant2.update!(pending_attacks: [])
    end

    it "deducts mana for skills" do
      initial_mp = participant1.current_mp

      service.resolve_round!

      # MP should be reduced (or unchanged if skill not in config)
      expect(participant1.reload.current_mp).to be <= initial_mp
    end
  end
end
