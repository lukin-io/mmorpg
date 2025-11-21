require "rails_helper"
require "ostruct"

RSpec.describe Game::Combat::TurnResolver do
  let(:attacker_stats) do
    Game::Systems::StatBlock.new(base: {attack: 12, crit_chance: 50}, mods: {})
  end

  let(:defender_stats) do
    Game::Systems::StatBlock.new(base: {defense: 4, luck: 10}, mods: {})
  end

  let(:attacker) { OpenStruct.new(name: "Warrior", stats: attacker_stats) }
  let(:defender) { OpenStruct.new(name: "Wolf", stats: defender_stats) }

  it "produces deterministic damage with seeded RNG" do
    result = described_class.new(
      attacker: attacker,
      defender: defender,
      action: "Slash",
      rng: Random.new(1)
    ).call

    expect(result.hp_changes[:defender]).to be_negative
    expect(result.log.first).to include("Slash")
  end
end
