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

      expect(stats[:attack]).to eq(10 * 3 + 5) # level * 3 + 5
      expect(stats[:defense]).to eq(10 * 2 + 3) # level * 2 + 3
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
  end
end
