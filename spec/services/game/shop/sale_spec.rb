# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::Sale do
  let(:character) { create(:character) }
  let(:inventory) { character.inventory }
  let(:wallet) { character.user.currency_wallet }
  let(:city) { create(:zone, location_type: "city") }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:hotspot) { create(:city_hotspot, :shop, zone: city, required_level: 1) }
  let(:template) do
    create(:item_template, base_price: 7, weight: 5, stack_limit: 1, durability_max: 10,
      enhancement_rules: {"subcategory" => "knives", "shop" => {"sold" => true}})
  end
  let!(:account) { ShopAccount.create!(location: hotspot, nv_balance: 1_000) }
  let!(:stock) { account.shop_stocks.create!(item_template: template, current: 5, maximum: 10) }
  let!(:item) { create(:inventory_item, inventory:, item_template: template, quantity: 1, weight: 5) }
  let(:maximum_balance) { BigDecimal("9999999999.99") }

  before do
    character.remember_gameplay_context!(name: "shop")
    wallet.update!(nv_balance: 100)
    inventory.update!(current_weight: 5)
    license_template = create(:item_template, item_type: "misc", slot: "none")
    license_offer = WorldActionOffer.create!(character:, zone: city, x: 5, y: 5,
      action_type: "shop_buy", status: :completed, target: license_template,
      action_key: SecureRandom.hex(16), expires_at: 10.minutes.from_now)
    CharacterLicense.create!(character:, item_template: license_template, world_action_offer: license_offer,
      kind: "trading", tier: 1, name: "Trading I", starts_at: 1.minute.ago, expires_at: 3.days.from_now)
  end

  def offered_sale
    Game::Shop::TradeOffers.new(character:).issue(sell_items: [item]).fetch(:sell).fetch(item.id)
  end

  it "rejects a wallet that no longer has storage headroom without changing any sale state" do
    offer = offered_sale
    wallet.update!(nv_balance: maximum_balance - BigDecimal("1.39"))
    original_item = item.reload.attributes
    original_offer = offer.reload.attributes

    result = described_class.new(character:, inventory_item: item, action_key: offer.action_key).call

    expect(result).to have_attributes(success: false, message: I18n.t("game.shop.wallet_payment_blocked"))
    expect(wallet.reload.nv_balance).to eq(maximum_balance - BigDecimal("1.39"))
    expect(wallet.currency_transactions).to be_empty
    expect(item.reload.attributes).to eq(original_item)
    expect(inventory.reload.current_weight).to eq(5)
    expect(account.reload.nv_balance).to eq(1_000)
    expect(stock.reload.current).to eq(5)
    expect(offer.reload.attributes).to eq(original_offer)
  end

  it "settles the last fractional wallet headroom at the exact storage maximum" do
    offer = offered_sale
    wallet.update!(nv_balance: maximum_balance - BigDecimal("1.40"))

    result = described_class.new(character:, inventory_item: item, action_key: offer.action_key).call

    expect(result).to have_attributes(success: true)
    expect(wallet.reload.nv_balance).to eq(maximum_balance)
    expect(wallet.currency_transactions.sole).to have_attributes(amount: BigDecimal("1.40"), balance_after: maximum_balance)
    expect(inventory.inventory_items.exists?(item.id)).to be(false)
    expect(inventory.reload.current_weight).to eq(0)
    expect(account.reload.nv_balance).to eq(BigDecimal("998.60"))
    expect(stock.reload.current).to eq(6)
    expect(offer.reload).to be_completed
  end

  it "rejects when the shop account lacks NV without mutating inventory" do
    offer = offered_sale
    account.update!(nv_balance: 0)
    original_qty = item.quantity

    result = described_class.new(character:, inventory_item: item, action_key: offer.action_key).call

    expect(result).to have_attributes(success: false, message: I18n.t("game.shop.shop_no_nv"))
    expect(item.reload.quantity).to eq(original_qty)
    expect(wallet.reload.nv_balance).to eq(100)
    expect(stock.reload.current).to eq(5)
  end

  it "rejects when shop stock cannot accept a return" do
    offer = offered_sale
    stock.update!(current: stock.maximum)

    result = described_class.new(character:, inventory_item: item, action_key: offer.action_key).call

    expect(result).to have_attributes(success: false, message: I18n.t("game.shop.shop_full"))
    expect(item.reload).to be_persisted
    expect(wallet.reload.nv_balance).to eq(100)
    expect(account.reload.nv_balance).to eq(1_000)
  end

  it "rejects sales without an active trading license" do
    CharacterLicense.where(character:).delete_all
    offer = offered_sale

    result = described_class.new(character:, inventory_item: item, action_key: offer.action_key).call

    expect(result.success).to be(false)
    expect(result.message).to eq(I18n.t("game.shop.sell_trading_license_required"))
    expect(item.reload).to be_persisted
    expect(wallet.reload.nv_balance).to eq(100)
  end
end
