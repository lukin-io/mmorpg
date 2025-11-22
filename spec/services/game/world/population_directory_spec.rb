# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PopulationDirectory do
  subject(:directory) { described_class.instance }

  describe "#npc" do
    it "wraps npc configuration with helper behavior" do
      npc = directory.npc("magistrate_serra")

      expect(npc).to be_present
      expect(npc.roles).to include("report_intake")
      expect(npc.reaction_for(reputation: 50)).to eq(:friendly)
    end
  end

  describe "#spawn_entries_for" do
    it "returns monster spawn definitions merged from yaml" do
      entries = directory.spawn_entries_for("ashen_forest")

      expect(entries).not_to be_empty
      expect(entries.first).to include("rarity")
    end
  end
end
