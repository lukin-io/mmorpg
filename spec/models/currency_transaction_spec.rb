# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrencyTransaction, type: :model do
  let(:wallet) { create(:user).currency_wallet }

  it "stores signed fractional amounts and fractional resulting balances" do
    transaction = wallet.currency_transactions.create!(
      amount: BigDecimal("-0.25"),
      balance_after: BigDecimal("12.50"),
      reason: "inventory.money_transfer.sent"
    )

    expect(described_class.columns_hash.fetch("amount").type).to eq(:decimal)
    expect(described_class.columns_hash.fetch("balance_after").type).to eq(:decimal)
    expect(transaction.reload).to have_attributes(
      amount: BigDecimal("-0.25"),
      balance_after: BigDecimal("12.50")
    )
  end

  it "rejects zero, null, or a negative resulting balance" do
    transaction = described_class.new(currency_wallet: wallet, reason: "edge")

    transaction.amount = 0
    transaction.balance_after = 0
    expect(transaction).not_to be_valid

    transaction.amount = nil
    expect(transaction).not_to be_valid

    transaction.amount = BigDecimal("0.01")
    transaction.balance_after = BigDecimal("-0.01")
    expect(transaction).not_to be_valid
  end

  it "rejects non-finite numeric values in the model and database" do
    [BigDecimal("NaN"), BigDecimal("Infinity"), BigDecimal("-Infinity")].each do |value|
      %i[amount balance_after].each do |column|
        attributes = {currency_wallet_id: wallet.id, amount: 1, balance_after: 1, reason: "edge",
                      created_at: Time.current, updated_at: Time.current}.merge(column => value)
        expect(described_class.new(attributes)).not_to be_valid
        expect do
          described_class.transaction(requires_new: true) { described_class.insert_all!([attributes]) }
        end.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end

  it "rejects zero amounts and negative resulting balances when validation is bypassed" do
    [{amount: 0, balance_after: 1}, {amount: 1, balance_after: -1}].each do |values|
      expect do
        described_class.transaction(requires_new: true) do
          described_class.insert_all!([{currency_wallet_id: wallet.id, reason: "edge",
                                       created_at: Time.current, updated_at: Time.current}.merge(values)])
        end
      end.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  context "Shop receipt retention" do
    let(:character) { create(:character, user: wallet.user) }
    let(:account) { ShopAccount.create!(location: create(:city_hotspot, :shop), nv_balance: 100) }
    let(:offer) do
      create(:world_action_offer, character:, action_type: "shop_buy", metadata: {"shop_account_id" => account.id})
    end
    let(:receipt_attributes) do
      {currency_wallet_id: wallet.id, amount: -7, balance_after: 93, reason: "shop.purchase",
       metadata: {"shop_offer_id" => offer.id, "shop_account_id" => account.id},
       created_at: Time.current, updated_at: Time.current}
    end
    let(:receipt) { described_class.create!(receipt_attributes) }

    it "derives foreign keys from existing metadata without fabricating a historical snapshot" do
      expect(receipt.reload).to have_attributes(shop_offer_id: offer.id, shop_account_id: account.id)
      expect(receipt.metadata).to eq("shop_offer_id" => offer.id, "shop_account_id" => account.id)
      expect(receipt.shop_offer).to eq(offer)
      expect(receipt.shop_account).to eq(account)
    end

    it "makes persisted Shop receipts read-only through the model" do
      expect { receipt.update!(amount: -8) }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { receipt.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      receipt.reason = "other"
      expect { receipt.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(receipt.reload.reason).to eq("shop.purchase")
    end

    it "blocks raw updates, reason changes and deletes" do
      record = receipt
      [-> { described_class.where(id: record.id).update_all(amount: -8) },
        -> { described_class.where(id: record.id).update_all(reason: "other") },
        -> { described_class.where(id: record.id).delete_all }].each do |operation|
        expect do
          described_class.transaction(requires_new: true) { operation.call }
        end.to raise_error(ActiveRecord::StatementInvalid, /append-only/)
      end
      expect(record.reload.amount).to eq(-7)
    end

    it "prevents converting an existing non-Shop ledger row into a Shop receipt" do
      record = described_class.create!(receipt_attributes.merge(reason: "other"))

      expect do
        described_class.transaction(requires_new: true) { described_class.where(id: record.id).update_all(reason: "shop.purchase") }
      end.to raise_error(ActiveRecord::StatementInvalid, /append-only/)
    end

    it "allows one receipt per Shop offer" do
      receipt

      expect do
        described_class.transaction(requires_new: true) { described_class.insert_all!([receipt_attributes]) }
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "requires integer references and matching wallet, action and account" do
      foreign = create(:world_action_offer, action_type: "shop_buy", metadata: {"shop_account_id" => account.id})
      other_account = ShopAccount.create!(location: create(:city_hotspot, :shop), nv_balance: 100)
      sell_offer = create(:world_action_offer, character:, action_type: "shop_sell", metadata: {"shop_account_id" => account.id})
      [{}, {"shop_offer_id" => offer.id.to_s, "shop_account_id" => account.id},
        {"shop_offer_id" => foreign.id, "shop_account_id" => account.id},
        {"shop_offer_id" => offer.id, "shop_account_id" => other_account.id},
        {"shop_offer_id" => sell_offer.id, "shop_account_id" => account.id}].each do |metadata|
        expect do
          described_class.transaction(requires_new: true) { described_class.insert_all!([receipt_attributes.merge(metadata:)]) }
        end.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    it "retains the referenced offer, Shop account and wallet" do
      receipt
      [offer, account, wallet].each do |parent|
        expect do
          described_class.transaction(requires_new: true) { parent.class.where(id: parent.id).delete_all }
        end.to raise_error(ActiveRecord::InvalidForeignKey)
      end
      expect { wallet.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(receipt.reload).to be_persisted
    end

    it "preserves ordinary non-Shop receipt edits and account deletion" do
      record = described_class.create!(currency_wallet: wallet, amount: 1, balance_after: 1, reason: "other")
      record.update!(amount: 2, balance_after: 2)
      expect(record.reload.amount).to eq(2)

      wallet.destroy!

      expect(described_class.exists?(record.id)).to be(false)
    end
  end
end
