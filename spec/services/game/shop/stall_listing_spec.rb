# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::StallListing do
  let(:seller) { create(:character) }
  let(:buyer) { create(:character) }
  let!(:seller_wallet) { seller.user.currency_wallet || seller.user.create_currency_wallet!(nv_balance: 2_000) }
  let!(:buyer_wallet) { buyer.user.currency_wallet || buyer.user.create_currency_wallet!(nv_balance: 500) }
  let(:template) do
    create(:item_template, :material, key: "ash_wolf_pelt", name: "Ash Wolf Pelt", weight: 10, stack_limit: 20)
  end

  before do
    seller_wallet.update!(nv_balance: 2_000)
    buyer_wallet.update!(nv_balance: 500)
    Game::Shop::StallRent.new(character: seller, stall_name: "Витрина угля").call
    inv = seller.inventory || seller.create_inventory!
    Game::Inventory::Manager.new(inventory: inv).add_item!(item_template: template, quantity: 2)
  end

  def seller_item
    seller.inventory.inventory_items.find_by!(item_template: template)
  end

  it "lists craft trade goods onto the rented stall" do
    result = described_class.new(
      character: seller,
      inventory_item_id: seller_item.id,
      quantity: 1,
      price_nv: 40
    ).list!

    expect(result.success).to be(true)
    listing = AuctionListing.open.sole
    expect(listing.metadata["listed_from"]).to eq("market_stall")
    expect(listing.metadata["stall_tax"]).to eq("15%")
    expect(seller.inventory.inventory_items.find_by(item_template: template).quantity).to eq(1)
  end

  it "rejects listing without an active lease" do
    seller.update!(metadata: {})
    item_id = seller_item.id

    result = described_class.new(
      character: seller,
      inventory_item_id: item_id,
      quantity: 1,
      price_nv: 40
    ).list!

    expect(result.success).to be(false)
    expect(AuctionListing.count).to eq(0)
  end

  it "buys a stall lot, applies tax as NV sink, and delivers the item" do
    described_class.new(
      character: seller,
      inventory_item_id: seller_item.id,
      quantity: 1,
      price_nv: 100
    ).list!
    listing = AuctionListing.open.sole

    result = described_class.new(character: buyer, listing_id: listing.id).buy!

    expect(result.success).to be(true)
    expect(buyer_wallet.reload.nv_balance).to eq(400)
    # 15% tax on 100 NV → seller gains 85
    expect(seller_wallet.reload.nv_balance).to eq(1_600 + 85)
    expect(listing.reload.status).to eq("sold")
    expect(buyer.inventory.inventory_items.find_by(item_template: template).quantity).to eq(1)
  end

  it "halves stall tax for seasonal craft-demand mats" do
    described_class.new(
      character: seller,
      inventory_item_id: seller_item.id,
      quantity: 1,
      price_nv: 100
    ).list!
    listing = AuctionListing.open.sole

    allow(Game::Seasons::Catalog).to receive(:active?).and_return(true)
    allow(Game::Seasons::Catalog).to receive(:current).and_return(
      "craft_demand_keys" => %w[ash_wolf_pelt]
    )

    before_seller = seller_wallet.reload.nv_balance.to_d
    result = described_class.new(character: buyer, listing_id: listing.id).buy!
    expect(result.success).to be(true)
    # Base stall tax 15% → half = 7.5% on 100 NV → seller +92.5
    expect(seller_wallet.reload.nv_balance.to_d).to eq(before_seller + BigDecimal("92.5"))
  end

  it "charges a feature fee and pins the lot to the top of open_rows" do
    before = seller_wallet.reload.nv_balance.to_d
    described_class.new(
      character: seller,
      inventory_item_id: seller_item.id,
      quantity: 1,
      price_nv: 40,
      featured: true
    ).list!

    expect(seller_wallet.reload.nv_balance.to_d).to eq(before - described_class::FEATURE_FEE_NV)
    listing = AuctionListing.open.sole
    expect(listing.metadata["featured"]).to eq(true)
    expect(described_class.open_rows.first.id).to eq(listing.id)
  end
end
