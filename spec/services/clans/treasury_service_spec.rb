# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clans::TreasuryService do
  let(:clan) { create(:clan, treasury_gold: 10_000) }
  let(:user) { create(:user) }
  let!(:membership) { create(:clan_membership, clan: clan, user: user, role: :quartermaster) }
  subject(:service) { described_class.new(clan: clan, actor: user, membership: membership) }

  describe "#deposit!" do
    it "increments the treasury and logs the transaction" do
      expect do
        service.deposit!(currency: :gold, amount: 500, reason: "test")
      end.to change { clan.reload.treasury_gold }.by(500)
        .and change { clan.clan_treasury_transactions.count }.by(1)
    end
  end

  describe "#withdraw!" do
    it "raises when the amount exceeds role limits" do
      limit = clan.withdrawal_limit_for(:quartermaster, :gold)
      expect do
        service.withdraw!(currency: :gold, amount: limit + 1, reason: "test")
      end.to raise_error(Clans::TreasuryService::LimitExceeded)
    end
  end
end
