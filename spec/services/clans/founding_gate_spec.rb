# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clans::FoundingGate do
  let(:user) { create(:user) }
  let(:required_level) { Rails.configuration.x.clans.dig("founding", "required_level").to_i }
  let(:quest_key) { Rails.configuration.x.clans.dig("founding", "quest_key") }
  let!(:quest) { create(:quest, key: quest_key) }
  let(:character) { create(:character, user: user, level: required_level) }
  let!(:quest_assignment) { create(:quest_assignment, quest: quest, character: character, status: :completed) }
  let!(:wallet) do
    user.currency_wallet.tap do |wallet|
      wallet.update!(gold_balance: 1_000_000)
    end
  end

  subject(:gate) { described_class.new(user: user, character: character, wallet: wallet) }

  describe "#enforce!" do
    it "deducts the founding fee when requirements are met" do
      expect { gate.enforce!(clan_name: "Vanguard") }.to change { wallet.reload.gold_balance }.by(-Rails.configuration.x.clans.dig("founding", "gold_fee").to_i)
    end

    it "raises when the character level is too low" do
      character.update!(level: required_level - 1)

      expect { gate.enforce!(clan_name: "Vanguard") }.to raise_error(Clans::FoundingGate::RequirementError)
    end
  end
end
