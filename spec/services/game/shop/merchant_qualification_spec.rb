# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::MerchantQualification do
  let(:character) { create(:character, perks: {"merchant" => true}) }
  let(:wallet) { character.user.currency_wallet }
  let(:market_zone) { create(:zone, :city_node, name: "Outpost Residential Quarter", metadata: {"city_key" => "forpost", "city_node_key" => "forpost1"}) }
  let(:shop_zone) { create(:zone, :city_node, name: "Outpost") }
  let!(:market) { create(:city_hotspot, :read_only_city_building, zone: market_zone) }
  let!(:shop) { create(:city_hotspot, :shop, zone: shop_zone) }
  let!(:account) { ShopAccount.create!(location: shop, nv_balance: 10) }
  let!(:position) { create(:character_position, character:, zone: market_zone, x: 0, y: 0) }
  let(:service) { described_class.new(character:) }

  before do
    wallet.update!(nv_balance: 1_500)
    enter(:market)
  end

  def enter(location)
    position.update!(zone: location == :market ? market_zone : shop_zone)
    character.reload
    if location == :market
      character.remember_gameplay_context!(name: "city_building", params: {building_key: "market"})
    else
      character.remember_gameplay_context!(name: "shop", params: {mode: "licenses"})
    end
  end

  def pay_receipt
    expect(service.call(action: :accept).success).to be true
    enter(:shop)
    expect(service.call(action: :pay).success).to be true
  end

  it "requires Market acceptance, charges one Shop receipt and unlocks only after returning" do
    inventory_before = character.inventory.attributes
    item_count = InventoryItem.count
    pay_receipt

    expect(wallet.reload.nv_balance).to eq(500)
    expect(account.reload.nv_balance).to eq(1_010)
    expect(service.status).to eq("paid")
    expect(character.metadata.to_h.dig("profession_unlocks", "merchant")).not_to be true
    ledger = wallet.currency_transactions.sole
    expect(ledger).to have_attributes(reason: described_class::PAYMENT_REASON, amount: -1_000)
    expect(ledger.metadata).to include("character_id" => character.id, "shop_account_id" => account.id)
    expect(character.metadata.fetch(described_class::STATE_KEY).fetch("receipt_transaction_id")).to eq(ledger.id)

    enter(:market)
    expect(service.call(action: :complete).success).to be true
    expect(character.reload.metadata.dig("profession_unlocks", "merchant")).to be true
    expect(service.status).to eq("completed")
    expect(character.inventory.reload.attributes).to eq(inventory_before)
    expect(InventoryItem.count).to eq(item_count)
    expect(CharacterLicense.where(character:)).to be_empty
  end

  it "makes repeated acceptance, payment and completion harmless" do
    2.times { expect(service.call(action: :accept).success).to be true }
    enter(:shop)
    2.times { expect(service.call(action: :pay).success).to be true }
    enter(:market)
    2.times { expect(service.call(action: :complete).success).to be true }
    enter(:shop)
    expect(service.call(action: :pay).success).to be true

    expect(wallet.reload.nv_balance).to eq(500)
    expect(account.reload.nv_balance).to eq(1_010)
    expect(wallet.currency_transactions.count).to eq(1)
  end

  it "rejects skipping steps and missing Merchant ownership without progress or payment" do
    expect(service.call(action: :complete).success).to be false
    enter(:shop)
    expect(service.call(action: :pay).success).to be false
    enter(:market)
    character.update!(perks: {})
    expect(service.call(action: :accept).message).to include("Merchant perk")

    expect(character.reload.metadata).not_to have_key(described_class::STATE_KEY)
    expect(wallet.reload.nv_balance).to eq(1_500)
    expect(account.reload.nv_balance).to eq(10)
  end

  it "rejects wrong city, wrong node, wrong saved room and inactive Market" do
    character.remember_gameplay_context!(name: "world")
    expect(service.call(action: :accept).success).to be false
    enter(:market)
    market.update!(active: false)
    expect(service.call(action: :accept).success).to be false
    market.update!(active: true)
    market_zone.update!(metadata: {"city_key" => "oktal", "city_node_key" => "forpost1"})
    expect(service.call(action: :accept).success).to be false
    enter(:shop)
    expect(service.call(action: :accept).success).to be false
    expect(character.reload.metadata).not_to have_key(described_class::STATE_KEY)
  end

  it "rejects a different Shop key or a missing economic account" do
    service.call(action: :accept)
    enter(:shop)
    shop.update!(key: "other_shop")
    expect(service.call(action: :pay).success).to be false
    shop.update!(key: "shop")
    account.destroy!
    expect(service.call(action: :pay).success).to be false
    expect(wallet.reload.nv_balance).to eq(1_500)
    expect(service.status).to eq("accepted")
  end

  it "rejects active movement and combat" do
    movement = create(:movement_command, :moving, character:, zone: market_zone)
    expect(service.call(action: :accept).success).to be false
    movement.update!(status: :completed)
    create(:arena_participation, character:, user: character.user, arena_match: create(:arena_match, :live))
    expect(service.call(action: :accept).success).to be false
    expect(character.reload.metadata).not_to have_key(described_class::STATE_KEY)
  end

  it "preserves accepted progress and both balances on insufficient payment" do
    service.call(action: :accept)
    enter(:shop)
    wallet.update!(nv_balance: 999.99)
    original = character.metadata.deep_dup

    expect(service.call(action: :pay).message).to include("Not enough NV")

    expect(character.reload.metadata).to eq(original)
    expect(wallet.reload.nv_balance).to eq(BigDecimal("999.99"))
    expect(account.reload.nv_balance).to eq(10)
    expect(wallet.currency_transactions).to be_empty
  end

  it "rolls back debit, Shop credit and receipt if saving paid progress fails" do
    service.call(action: :accept)
    enter(:shop)
    allow(character).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(character))

    expect { service.call(action: :pay) }.to raise_error(ActiveRecord::RecordInvalid)

    expect(wallet.reload.nv_balance).to eq(1_500)
    expect(account.reload.nv_balance).to eq(10)
    expect(wallet.currency_transactions).to be_empty
    expect(character.reload.metadata.dig(described_class::STATE_KEY, "status")).to eq("accepted")
  end

  it "does not trust a forged paid state without this character's receipt" do
    character.update!(metadata: character.metadata.merge(described_class::STATE_KEY => {
      "status" => "paid", "accepted_at" => Time.current.iso8601, "paid_at" => Time.current.iso8601,
      "receipt_transaction_id" => -1
    }))

    expect(service.call(action: :complete).success).to be false
    expect(character.reload.metadata.dig("profession_unlocks", "merchant")).not_to be true
  end

  it "fails closed for malformed progress while preserving existing explicit qualifications" do
    character.update!(metadata: character.metadata.merge("profession_unlocks" => "bad", described_class::STATE_KEY => "bad"))
    expect(service.status).to eq("invalid")
    expect(service.call(action: :accept).success).to be false
    character.update!(metadata: character.metadata.merge("profession_unlocks" => {"merchant" => true}))
    enter(:shop)
    expect(service.call(action: :pay).success).to be true
    expect(wallet.reload.nv_balance).to eq(1_500)
  end

  it "serializes two receipt payments into one debit", js: true do
    service.call(action: :accept)
    enter(:shop)
    character_id = character.id
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.new(character: Character.find(character_id)).call(action: :pay)
        end
      end
    end

    expect(threads.map(&:value).map(&:success)).to eq([true, true])
    expect(wallet.reload.nv_balance).to eq(500)
    expect(account.reload.nv_balance).to eq(1_010)
    expect(wallet.currency_transactions.count).to eq(1)
  end
end
