# frozen_string_literal: true

require "rails_helper"

RSpec.describe Npc::Combatable do
  let(:hostile_npc) { create(:npc_template, role: "hostile", level: 10) }
  let(:arena_bot) { create(:npc_template, role: "arena_bot", level: 10) }

  describe "#can_engage_combat?" do
    it "allows source-backed hostile NPCs and arena bots" do
      expect(hostile_npc.can_engage_combat?).to be true
      expect(arena_bot.can_engage_combat?).to be true
    end
  end

  describe "#hostile?" do
    it "is true only for outdoor hostile NPCs" do
      expect(hostile_npc.hostile?).to be true
      expect(arena_bot.hostile?).to be false
    end
  end

  describe "#combat_behavior" do
    it "defaults hostile NPCs to aggressive behavior" do
      expect(hostile_npc.combat_behavior).to eq(:aggressive)
    end

    it "defaults arena bots to passive behavior without captured metadata" do
      expect(arena_bot.combat_behavior).to eq(:passive)
    end

    it "uses a source-backed metadata override when present" do
      hostile_npc.update!(metadata: {"ai_behavior" => "passive"})

      expect(hostile_npc.combat_behavior).to eq(:passive)
    end
  end

  describe "#should_defend?" do
    it "does not invent defensive behavior without source-backed metadata" do
      expect(hostile_npc.should_defend?(current_hp_ratio: 0.01, rng: Random.new(1))).to be false
    end

    it "uses explicit source-backed defense metadata when present" do
      hostile_npc.update!(metadata: {"defend_hp_below" => 0.5, "defend_chance" => 1.0})

      expect(hostile_npc.should_defend?(current_hp_ratio: 0.25, rng: Random.new(1))).to be true
      expect(hostile_npc.should_defend?(current_hp_ratio: 0.75, rng: Random.new(1))).to be false
    end
  end
end
