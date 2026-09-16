# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hospital purchases", type: :request do
  let(:character) { create(:character, level: 17) }
  let(:city) { create(:zone, :city_node) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:hospital) { create(:city_hotspot, :read_only_city_building, zone: city, key: "hospital", name: "Hospital", action_params: {"feature" => "hospital"}) }
  let!(:account) { ShopAccount.create!(location: hospital, nv_balance: 0) }
  let!(:bag) do
    create(:item_template, key: "beginner_healer_bag", name: "Beginner healer bag", item_type: "misc", slot: "none",
      weight: 1, base_price: 300, durability_max: 10, requirements: {"knowledge" => 20, "doctor" => 100},
      stat_modifiers: {"heals_injury" => "light"},
      enhancement_rules: {"inventory_family" => "things", "subcategory" => "aid_kits", "shop" => {"sold" => true}})
  end
  let!(:stock) { ShopStock.create!(shop_account: account, item_template: bag, current: 2, maximum: 2) }

  before do
    character.user.currency_wallet.update!(nv_balance: 1000)
    sign_in character.user
  end

  def enter_and_quote
    get city_building_path("hospital")
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Buy Beginner healer bag", "Doctor 100")
    expect(Nokogiri::HTML(response.body).at_css("form[action='#{hospital_purchase_path(building_key: 'hospital')}']")["data-turbo-frame"]).to eq("_top")
    WorldActionOffer.offered.find_by!(character:, action_type: "shop_buy", target: bag)
  end

  it "buys into Inventory exactly once using the Hospital's stock and account" do
    offer = enter_and_quote
    2.times { post hospital_purchase_path(building_key: "hospital"), params: {item_key: bag.key, action_key: offer.action_key} }
    expect(response).to redirect_to(city_building_path("hospital"))
    expect(character.inventory.inventory_items.where(item_template: bag).sum(:quantity)).to eq(1)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(700)
    expect(account.reload.nv_balance).to eq(300)
    expect(stock.reload.current).to eq(1)
    get inventory_path(category: "things", subcategory: "aid_kits")
    expect(response.body).to include("Beginner healer bag")
  end

  it "revalidates funds and location before spending a quoted offer" do
    offer = enter_and_quote
    character.user.currency_wallet.update!(nv_balance: 299)
    post hospital_purchase_path(building_key: "hospital"), params: {item_key: bag.key, action_key: offer.action_key}
    expect(character.inventory.inventory_items.where(item_template: bag)).to be_empty
    expect(stock.reload.current).to eq(2)
    expect(account.reload.nv_balance).to eq(0)
    character.user.currency_wallet.update!(nv_balance: 1000)
    position.update!(zone: create(:zone, :city_node))
    post hospital_purchase_path(building_key: "hospital"), params: {item_key: bag.key, action_key: offer.action_key}
    expect(response).to redirect_to(world_path)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(1000)
    expect(stock.reload.current).to eq(2)
  end
end
