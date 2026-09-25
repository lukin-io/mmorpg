# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Activity::AchievementCatalog do
  it "exposes leveled chat and kill chains through legendary" do
    chat = described_class.chains_for("chat_message")
    expect(chat.map { |row| row[:tier] }).to eq(%w[I II III legendary])
    expect(chat.map { |row| row[:required] }).to eq([10, 50, 200, 1000])

    kills = described_class.chains_for("kill_npc")
    expect(kills.last[:tier]).to eq("legendary")
    expect(kills.last[:required]).to eq(1000)
  end
end

RSpec.describe Game::Skills::UseTrainer do
  it "grows uncapped weapon mastery from combat hits" do
    character = create(:character)
    trainer = described_class.new(character:)

    expect {
      3.times { trainer.train_from_combat_hit!(weapon_family: "sword") }
    }.to change { character.reload.passive_skill_level(:sword_mastery) }.by_at_least(1)

    expect(described_class.weapon_damage_multiplier(character.reload, "sword")).to be > 1.0
  end
end
