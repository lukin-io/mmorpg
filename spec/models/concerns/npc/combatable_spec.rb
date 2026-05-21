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

    it "defaults arena bots to balanced behavior" do
      expect(arena_bot.combat_behavior).to eq(:balanced)
    end

    it "uses a source-backed metadata override when present" do
      hostile_npc.update!(metadata: {"ai_behavior" => "defensive"})

      expect(hostile_npc.combat_behavior).to eq(:defensive)
    end
  end

  describe "#can_flee?" do
    it "prevents arena bots from fleeing" do
      expect(arena_bot.can_flee?).to be false
    end

    it "allows hostile NPCs to flee unless metadata disables it" do
      expect(hostile_npc.can_flee?).to be true

      hostile_npc.update!(metadata: {"can_flee" => false})
      expect(hostile_npc.can_flee?).to be false
    end
  end
end
