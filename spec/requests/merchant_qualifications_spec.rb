# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Merchant qualification", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, perks: {"merchant" => true}) }
  let(:market_zone) { create(:zone, :city_node, name: "Outpost Residential Quarter", metadata: {"city_key" => "forpost", "city_node_key" => "forpost1"}) }
  let(:shop_zone) { create(:zone, :city_node, name: "Outpost") }
  let!(:market) { create(:city_hotspot, :read_only_city_building, zone: market_zone) }
  let!(:shop) { create(:city_hotspot, :shop, zone: shop_zone) }
  let!(:account) { ShopAccount.create!(location: shop, nv_balance: 10) }
  let!(:position) { create(:character_position, character:, zone: market_zone, x: 0, y: 0) }

  before do
    user.currency_wallet.update!(nv_balance: 1_500)
    sign_in user, scope: :user
  end

  it "requires authentication for every step" do
    sign_out :user
    [accept_merchant_qualification_path, pay_merchant_qualification_path, complete_merchant_qualification_path].each do |path|
      post path
      expect(response).to redirect_to(new_user_session_path)
    end
    expect(character.reload.metadata).not_to have_key("merchant_qualification")
  end

  it "renders and persists the three ordered qualification steps without an inventory receipt" do
    get city_building_path("market")
    expect(response.body).to include("Accept Merchant qualification")
    post accept_merchant_qualification_path
    expect(response).to redirect_to(city_building_path("market"))
    expect(character.reload.metadata.dig("merchant_qualification", "status")).to eq("accepted")

    position.update!(zone: shop_zone)
    get shop_path(mode: "licenses")
    expect(response.body).to include("Pay 1,000 NV and collect receipt")
    post pay_merchant_qualification_path
    expect(response).to redirect_to(shop_path(mode: "licenses"))
    expect(character.reload.metadata.dig("merchant_qualification", "status")).to eq("paid")
    expect(user.currency_wallet.reload.nv_balance).to eq(500)
    expect(account.reload.nv_balance).to eq(1_010)

    position.update!(zone: market_zone)
    get city_building_path("market")
    expect(response.body).to include("Complete Merchant qualification")
    post complete_merchant_qualification_path
    expect(response).to redirect_to(city_building_path("market"))
    expect(character.reload.metadata.dig("profession_unlocks", "merchant")).to be true
    expect(character.inventory.inventory_items).to be_empty
  end

  it "ignores submitted owner, fee, qualification and receipt data" do
    other = create(:character, perks: {"merchant" => true})
    get city_building_path("market")
    post complete_merchant_qualification_path, params: {
      character_id: other.id, fee: 0, receipt_transaction_id: 1,
      metadata: {profession_unlocks: {merchant: true}, merchant_qualification: {status: "paid"}}
    }
    expect(response).to have_http_status(:see_other)
    expect(character.reload.metadata.dig("profession_unlocks", "merchant")).not_to be true
    expect(other.reload.metadata.dig("profession_unlocks", "merchant")).not_to be true
    expect(user.currency_wallet.reload.nv_balance).to eq(1_500)
  end

  it "rejects direct steps from an unrelated saved room and hides controls without Merchant" do
    character.remember_gameplay_context!(name: "world")
    post accept_merchant_qualification_path
    expect(character.reload.metadata).not_to have_key("merchant_qualification")
    character.update!(perks: {})
    get city_building_path("market")
    expect(response.body).not_to include("Accept Merchant qualification")
    post accept_merchant_qualification_path
    expect(character.reload.metadata).not_to have_key("merchant_qualification")
  end
end
