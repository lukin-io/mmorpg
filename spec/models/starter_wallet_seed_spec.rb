# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/starter_wallet_grant")

RSpec.describe Seeds::StarterWalletGrant, type: :model do
  let(:user) { create(:user) }
  let(:wallet) { user.currency_wallet }

  it "grants initial NV once without replacing an existing balance" do
    wallet.update!(nv_balance: 60)

    expect { described_class.call(user:, amount: 7_500, metadata: {"source" => "starter_content"}) }
      .to change { wallet.reload.balance }.from(60).to(7_560)

    transaction = wallet.currency_transactions.sole
    expect(transaction).to have_attributes(reason: "seed.initial_nv", amount: 7_500, balance_after: 7_560)
    expect(transaction.metadata).to eq("source" => "starter_content", "seed_grant_key" => "starter_initial_nv_v1")
    original = wallet.attributes
    expect(described_class.call(user:, amount: 9_000)).to eq(wallet)
    expect(wallet.reload.attributes).to eq(original)
    expect(wallet.currency_transactions.reload).to eq([transaction])
  end

  it "recognizes historical seed grants without changing the balance or repairing old ledger entries" do
    wallet.adjust!(amount: 4_200, reason: "seed.initial_nv")
    wallet.adjust!(amount: -80, reason: "shop.buy")
    original_wallet = wallet.attributes
    original_transactions = wallet.currency_transactions.order(:id).map(&:attributes)

    described_class.call(user:, amount: 4_200)

    expect(wallet.reload.attributes).to eq(original_wallet)
    expect(wallet.currency_transactions.order(:id).map(&:attributes)).to eq(original_transactions)
  end

  it "creates a missing wallet and uses the ordinary wallet/ledger writer" do
    wallet.destroy!

    expect { described_class.call(user:, amount: 4_200) }.to change(CurrencyWallet, :count).by(1)

    created = CurrencyWallet.find_by!(user:)
    expect(created.balance).to eq(4_200)
    expect(created.currency_transactions.sole.reason).to eq("seed.initial_nv")
  end

  it "rolls back the credit when its ledger row cannot be written" do
    wallet.update!(nv_balance: 60)
    allow(CurrencyWallet).to receive(:find_by).with(user:).and_return(wallet)
    transactions = wallet.currency_transactions
    allow(wallet).to receive(:currency_transactions).and_return(transactions)
    allow(transactions).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    expect { described_class.call(user:, amount: 7_500) }.to raise_error(ActiveRecord::RecordInvalid)

    expect(wallet.reload.balance).to eq(60)
    expect(wallet.currency_transactions).to be_empty
  end

  it "keeps initial grants stable when the complete seed bootstrap runs again" do
    allow($stdout).to receive(:puts)
    Rails.application.load_seed
    first = User.find_by!(email: "first@lukin.io").currency_wallet
    second = User.find_by!(email: "second@lukin.io").currency_wallet
    first.adjust!(amount: -75, reason: "shop.buy")
    before = [first.reload.balance, second.reload.balance, CurrencyTransaction.count]

    Rails.application.load_seed

    expect([first.reload.balance, second.reload.balance, CurrencyTransaction.count]).to eq(before)
    expect(first.currency_transactions.where(reason: "seed.initial_nv").count).to eq(1)
    expect(second.currency_transactions.where(reason: "seed.initial_nv").count).to eq(1)
  end

  # js metadata selects truncation, exposing setup to independent DB connections.
  [true, false].each do |wallet_exists|
    it "serializes competing bootstrap grants with wallet_exists=#{wallet_exists}", js: true do
      user_id = user.id
      wallet.destroy! unless wallet_exists
      gate = Queue.new
      results = Queue.new
      workers = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            gate.pop
            results << described_class.call(user: User.find(user_id), amount: 7_500).id
          rescue => error
            results << error
          end
        end
      end
      2.times { gate << true }
      workers.each { |worker| expect(worker.join(10)).to eq(worker) }

      persisted = CurrencyWallet.find_by!(user:)
      expect(2.times.map { results.pop }.uniq).to eq([persisted.id])
      expect(persisted.balance).to eq(7_500)
      expect(persisted.currency_transactions.where(reason: "seed.initial_nv").count).to eq(1)
    end
  end
end
