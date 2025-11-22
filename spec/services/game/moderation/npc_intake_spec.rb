# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Moderation::NpcIntake do
  subject(:service) { described_class.new }

  let(:user) { create(:user) }

  describe "#call" do
    it "creates an npc report when npc accepts reports" do
      report = service.call(
        reporter: user,
        npc_key: "magistrate_serra",
        category: "chat_abuse",
        description: "Player used slurs",
        evidence: {"location" => "Grand Bazaar"}
      )

      expect(report).to be_persisted
      expect(report.metadata["region"]).to eq("everfall_capital")
    end

    it "raises when npc does not accept reports" do
      expect do
        service.call(
          reporter: user,
          npc_key: "vendor_luthe",
          category: "chat_abuse",
          description: "Test"
        )
      end.to raise_error(Game::Moderation::NpcIntake::InvalidNpc)
    end
  end
end
