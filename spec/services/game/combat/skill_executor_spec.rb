# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Game::Combat::SkillExecutor do
  let(:character) { create(:character, :with_position, current_mp: 50, max_mp: 50) }
  let(:target) { create(:character, :with_position, current_hp: 100, max_hp: 100) }
  let(:arena_match) { create(:arena_match, :live) }

  before do
    create(:arena_participation, arena_match:, character:, user: character.user, team: "a")
    create(:arena_participation, arena_match:, character: target, user: target.user, team: "b")
  end

  describe ".available_skills" do
    it "returns no legacy class or skill-tree active skills" do
      expect(described_class.available_skills(character)).to eq([])
    end
  end

  describe "#execute!" do
    it "deals damage and writes to the arena fight log" do
      skill = skill_record(
        id: 1,
        name: "Slash",
        effects: {"type" => "damage", "base_damage" => 30, "scaling_stat" => "strength", "scaling_factor" => 0.5}
      )

      executor = described_class.new(caster: character, target:, skill:, fight: arena_match)

      expect { executor.execute! }.to change { arena_match.combat_log_entries.count }.by(1)

      result = executor.execute!
      expect(result.success).to be true
      expect(result.damage).to be_positive
    end

    it "stores cooldowns on the arena match metadata" do
      skill = skill_record(id: 2, name: "Guard", effects: {"type" => "shield"}, cooldown_seconds: 30)

      result = described_class.new(caster: character, target: character, skill:, fight: arena_match).execute!

      expect(result.success).to be true
      expect(arena_match.reload.metadata.dig("cooldowns", "skill_2_cooldown")).to be_present
    end

    it "applies buffs to arena participation metadata" do
      skill = skill_record(
        id: 3,
        name: "Rally",
        effects: {"type" => "buff", "buff_stat" => "strength", "buff_value" => 10, "duration" => 3}
      )

      result = described_class.new(caster: character, target: character, skill:, fight: arena_match).execute!

      participation = arena_match.arena_participations.find_by(character:)
      expect(result.success).to be true
      expect(participation.reload.metadata["combat_buffs"]).to be_present
    end
  end

  def skill_record(id:, name:, effects:, resource_cost: {}, cooldown_seconds: 0)
    OpenStruct.new(id:, name:, effects:, resource_cost:, cooldown_seconds:)
  end
end
