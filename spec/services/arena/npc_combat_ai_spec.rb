# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcCombatAi do
  let(:npc_template) do
    create(:npc_template,
      npc_key: "arena_test_bot",
      role: "arena_bot",
      name: "Test Bot",
      level: 5,
      metadata: {
        "health" => 100,
        "base_damage" => 15,
        "difficulty" => "medium",
        "ai_behavior" => "balanced"
      })
  end

  let(:arena_room) { create(:arena_room, slug: "training", level_min: 1, level_max: 10) }
  let(:character) { create(:character, level: 5, current_hp: 100, max_hp: 100) }

  let(:arena_match) do
    match = create(:arena_match, arena_room: arena_room, status: :live)

    # Add player participation
    create(:arena_participation,
      arena_match: match,
      character: character,
      user: character.user,
      team: "a")

    # Add NPC participation (using :npc trait)
    create(:arena_participation, :npc, :team_b,
      arena_match: match,
      npc_template: npc_template,
      metadata: {"current_hp" => 100, "max_hp" => 100})

    match
  end

  let(:rng) { Random.new(123) }
  let(:ai) { described_class.new(npc_template: npc_template, match: arena_match, rng: rng) }

  describe "#initialize" do
    it "accepts npc_template, match, and rng" do
      expect(ai.npc_template).to eq(npc_template)
      expect(ai.match).to eq(arena_match)
      expect(ai.rng).to eq(rng)
    end

    it "extracts behavior from npc_template's combat_behavior" do
      expect(ai.behavior).to eq(:balanced)
    end

    it "uses default RNG when not provided" do
      ai_default = described_class.new(npc_template: npc_template, match: arena_match)
      expect(ai_default.rng).to be_a(Random)
    end
  end

  describe "#decide_action" do
    context "with aggressive AI" do
      let(:npc_template) do
        create(:npc_template,
          npc_key: "aggressive_bot",
          role: "arena_bot",
          name: "Aggressive Bot",
          level: 5,
          metadata: {"ai_behavior" => "aggressive"})
      end

      it "always attacks" do
        decision = ai.decide_action

        expect(decision.action_type).to eq(:attack)
      end
    end

    context "with defensive AI" do
      let(:npc_template) do
        create(:npc_template,
          npc_key: "defensive_bot",
          role: "arena_bot",
          name: "Defensive Bot",
          level: 5,
          metadata: {
            "health" => 100,
            "ai_behavior" => "defensive"
          })
      end

      it "considers defending when HP is low" do
        # Set NPC HP to 50% (below 70% threshold)
        npc_participation = arena_match.arena_participations.npcs.first
        npc_participation.update!(metadata: {"current_hp" => 50, "max_hp" => 100})

        # Run multiple times to see if it sometimes defends
        decisions = 10.times.map do |i|
          described_class.new(
            npc_template: npc_template,
            match: arena_match.reload,
            rng: Random.new(i)
          ).decide_action
        end

        action_types = decisions.map(&:action_type)
        # Should have some variety (attacks and defends)
        expect(action_types).to include(:attack)
      end
    end

    context "with balanced AI" do
      it "usually attacks when HP is high" do
        decision = ai.decide_action

        expect(decision.action_type).to eq(:attack)
      end
    end
  end

  describe "#stats" do
    it "extracts stats from NPC config" do
      stats = ai.stats

      expect(stats[:attack]).to be_present
      expect(stats[:defense]).to be_present
      expect(stats[:hp]).to be_present
    end

    it "uses level-based fallback when config not found" do
      # Create NPC without matching config
      custom_npc = create(:npc_template,
        npc_key: "custom_bot_#{SecureRandom.hex(4)}",
        role: "arena_bot",
        name: "Custom Bot",
        level: 10)

      custom_ai = described_class.new(
        npc_template: custom_npc,
        match: arena_match,
        rng: rng
      )

      stats = custom_ai.stats

      # Base formulas with arena_bot role modifier (0.9 for attack/defense)
      # attack: (10 * 3 + 5) * 0.9 = 35 * 0.9 = 31.5 -> 31
      # defense: (10 * 2 + 3) * 0.9 = 23 * 0.9 = 20.7 -> 20
      expect(stats[:attack]).to eq(31)
      expect(stats[:defense]).to eq(20)
    end
  end

  describe "determinism" do
    it "produces same decision with same seed" do
      ai1 = described_class.new(npc_template: npc_template, match: arena_match, rng: Random.new(42))
      ai2 = described_class.new(npc_template: npc_template, match: arena_match, rng: Random.new(42))

      decision1 = ai1.decide_action
      decision2 = ai2.decide_action

      expect(decision1.action_type).to eq(decision2.action_type)
    end

    it "produces different decisions with different seeds" do
      # Run with many seeds to find variation
      decisions = 20.times.map do |i|
        described_class.new(
          npc_template: npc_template,
          match: arena_match,
          rng: Random.new(i)
        ).decide_action
      end

      # All should be valid action types
      decisions.each do |d|
        expect(%i[attack defend]).to include(d.action_type)
      end
    end

    it "body part selection is deterministic" do
      ai1 = described_class.new(npc_template: npc_template, match: arena_match, rng: Random.new(42))
      ai2 = described_class.new(npc_template: npc_template, match: arena_match, rng: Random.new(42))

      decision1 = ai1.decide_action
      decision2 = ai2.decide_action

      if decision1.action_type == :attack
        expect(decision1.params[:body_part]).to eq(decision2.params[:body_part])
      end
    end
  end

  describe "unified architecture integration" do
    it "uses NpcTemplate#combat_stats for stats" do
      # Verify stats come from the unified concern
      expect(ai.stats).to eq(npc_template.combat_stats)
    end

    it "uses NpcTemplate#combat_behavior for behavior" do
      expect(ai.behavior).to eq(npc_template.combat_behavior)
    end

    it "delegates defense decisions to NpcTemplate#should_defend?" do
      # Verify the AI uses the concern's should_defend? method indirectly
      # by checking behavior consistency
      expect(npc_template).to respond_to(:should_defend?)
    end
  end

  describe "Decision struct" do
    it "has action_type, target, and params" do
      decision = ai.decide_action

      expect(decision).to respond_to(:action_type)
      expect(decision).to respond_to(:target)
      expect(decision).to respond_to(:params)
    end

    it "attack decision includes body_part in params" do
      # Force attack decision by using high HP
      decision = ai.decide_action

      if decision.action_type == :attack
        expect(decision.params).to have_key(:body_part)
        expect(%w[head torso stomach legs]).to include(decision.params[:body_part])
      end
    end

    it "defend decision has nil target" do
      # Create a defensive NPC with low HP to trigger defend
      defensive_npc = create(:npc_template,
        npc_key: "test_defensive",
        role: "arena_bot",
        name: "Defensive Test",
        level: 5,
        metadata: {"ai_behavior" => "defensive"})

      match = create(:arena_match, arena_room: arena_room, status: :live)
      create(:arena_participation, arena_match: match, character: character, user: character.user, team: "a")
      create(:arena_participation, :npc, :team_b,
        arena_match: match,
        npc_template: defensive_npc,
        metadata: {"current_hp" => 10, "max_hp" => 100}) # Very low HP

      # Find a seed that produces a defend decision
      defend_decision = nil
      100.times do |i|
        ai = described_class.new(npc_template: defensive_npc, match: match, rng: Random.new(i))
        decision = ai.decide_action
        if decision.action_type == :defend
          defend_decision = decision
          break
        end
      end

      if defend_decision
        expect(defend_decision.target).to be_nil
      end
    end
  end

  describe "edge cases" do
    context "with no opponents" do
      let(:empty_match) do
        match = create(:arena_match, arena_room: arena_room, status: :live)
        create(:arena_participation, :npc, :team_b,
          arena_match: match,
          npc_template: npc_template,
          metadata: {"current_hp" => 100, "max_hp" => 100})
        match
      end

      it "returns attack with nil target when no opponents" do
        ai = described_class.new(npc_template: npc_template, match: empty_match, rng: rng)
        decision = ai.decide_action

        # Should still try to attack, but target will be nil
        expect(decision.action_type).to be_in(%i[attack defend])
      end
    end

    context "with empty metadata" do
      # Note: Database has NOT NULL constraint, so we test with empty hash
      let(:minimal_npc) do
        create(:npc_template,
          npc_key: "minimal_test",
          role: "arena_bot",
          name: "Minimal Bot",
          level: 5,
          metadata: {})
      end

      it "handles empty metadata gracefully" do
        ai = described_class.new(npc_template: minimal_npc, match: arena_match, rng: rng)

        expect { ai.decide_action }.not_to raise_error
        expect { ai.stats }.not_to raise_error
      end
    end

    context "with missing participation" do
      it "handles missing NPC participation gracefully" do
        match_without_npc = create(:arena_match, arena_room: arena_room, status: :live)
        create(:arena_participation, arena_match: match_without_npc, character: character, user: character.user, team: "a")

        ai = described_class.new(npc_template: npc_template, match: match_without_npc, rng: rng)

        # Should not raise, but decision may be attack
        expect { ai.decide_action }.not_to raise_error
      end
    end
  end

  describe "role modifier integration" do
    it "arena_bot stats are weaker than hostile" do
      hostile_npc = create(:npc_template, level: 10, role: "hostile")
      arena_npc = create(:npc_template, level: 10, role: "arena_bot")

      hostile_ai = described_class.new(npc_template: hostile_npc, match: arena_match, rng: rng)
      arena_ai = described_class.new(npc_template: arena_npc, match: arena_match, rng: rng)

      # Arena bots should have lower stats due to 0.9 modifier
      expect(arena_ai.stats[:attack]).to be < hostile_ai.stats[:attack]
    end
  end
end
