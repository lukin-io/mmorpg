# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Targeted attack scrolls", type: :request do
  let(:attacker) { create(:character, level: 17, passive_skills: {"stealth" => 20}) }
  let(:target) { create(:character, level: 17) }
  let(:zone) { create(:zone, location_type: "city", name: "Scroll Test City") }
  let!(:shop) { create(:city_hotspot, :shop, zone:, required_level: 1) }
  let!(:account) { ShopAccount.create!(location: shop, nv_balance: 1000) }
  let(:template) do
    attributes = JSON.parse(File.read(Rails.root.join("db/seeds/data/starter_shop.json"))).find { |row| row["key"] == "duel_permit_i" }
    ItemTemplate.create!(attributes.except("shop_stock"))
  end

  before do
    [attacker, target].each { |player| create(:character_position, character: player, zone:) }
    create(:user_session, user: target.user, last_seen_at: Time.current)
    attacker.user.currency_wallet.update!(nv_balance: 500)
    ShopStock.create!(shop_account: account, item_template: template, current: 10, maximum: 500)
    sign_in attacker.user
  end

  def open_use_form
    get inventory_path(scroll_item_id: @item.id, category: "things", subcategory: "scrolls")
    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css(".nl-scroll-use h2").text).to eq("Ordinary attack")
    expect(document.at_css("label[for='target_name']").text).to eq("Target nickname:")
    document.at_css(".nl-scroll-use input[name='action_key']")["value"]
  end

  def acquire_scroll
    get shop_path(category: "scrolls")
    offer = WorldActionOffer.find_by!(character: attacker, target: template, action_type: "shop_buy", status: :offered)
    post buy_shop_path, params: {item_template_id: template.id, action_key: offer.action_key}
    @item = attacker.inventory.inventory_items.find_by!(item_template: template)
    expect(attacker.user.currency_wallet.reload.nv_balance).to eq(484)
  end

  it "buys, opens Use, validates, enters shared PvP, exchanges turns and independently finishes to prior context" do
    acquire_scroll
    target.remember_gameplay_context!(name: "shop", params: {category: "scrolls"})
    key = open_use_form
    post scroll_use_path, params: {action_key: key, target_name: "Unknown Target"}
    expect(response).to redirect_to(inventory_path(category: "things", subcategory: "scrolls"))
    expect(@item.reload.quantity).to eq(1)

    post scroll_use_path, params: {action_key: key, target_name: target.name,
      trauma_percent: 100, source: "arena", fight_kind: "closed", target_id: attacker.id}
    match = ArenaMatch.sole
    expect(response).to redirect_to(arena_match_path(match))
    expect(match.trauma_percent).to eq(10)
    expect(match.metadata["fight_kind"]).to eq("free")
    get arena_match_path(match)
    expect(response.body).to include("Trauma: <b>10%</b>")
    expect(response.body).to include("started (attack)")
    expect(InventoryItem.exists?(@item.id)).to be(false)
    get inventory_path
    expect(response).to redirect_to(arena_match_path(match))

    turn = {action_type: "turn", turn_number: 1,
      attacks: [{action_key: "simple", body_part: "head"}],
      blocks: [{action_key: "head_block", body_parts: ["head"]}]}
    post action_arena_match_path(match), params: turn.merge(target_id: target.id), as: :json
    expect(response.parsed_body.dig("data", "waiting")).to be(true)
    sign_out attacker.user
    sign_in target.user
    post combat_status_path, as: :json
    expect(response.parsed_body).to include("interrupted" => true, "redirect_url" => arena_match_path(match))
    post action_arena_match_path(match), params: turn.merge(target_id: attacker.id), as: :json
    expect(response.parsed_body.dig("data", "resolved")).to be(true)
    expect(match.reload.current_turn_number).to eq(2)

    post action_arena_match_path(match), params: {action_type: "surrender"}, as: :json
    expect(match.reload).to be_completed
    expect(GameEvent.where(event_type: :fight_finished)).to be_empty
    post combat_status_path, as: :json
    expect(response.parsed_body["interrupted"]).to be(true)
    post finish_arena_match_path(match)
    expect(response).to redirect_to(shop_path(mode: "buy", category: "scrolls"))
    expect(GameEvent.where(event_type: :fight_finished).pluck(:recipient_id)).to eq([target.user_id])
    post finish_arena_match_path(match)
    expect(GameEvent.where(event_type: :fight_finished).count).to eq(1)
    post combat_status_path, as: :json
    expect(response.parsed_body["interrupted"]).to be(false)

    sign_out target.user
    sign_in attacker.user
    post finish_arena_match_path(match)
    expect(response).to redirect_to(inventory_path)
    notice = GameEvent.find_by!(event_type: :fight_finished, recipient: attacker.user)
    expect(notice.payload["experience"]).to eq(match.arena_participations.find_by!(character: attacker).metadata["experience_awarded"].to_i)
    post finish_arena_match_path(match)
    expect(GameEvent.where(event_type: :fight_finished).count).to eq(2)
    post scroll_use_path, params: {action_key: key, target_name: target.name}
    expect(response).to redirect_to(arena_match_path(match))
    expect(ArenaMatch.count).to eq(1)
  end

  it "rejects attack across distinct city interiors on identical coordinates" do
    acquire_scroll
    key = open_use_form
    post scroll_use_path, params: {action_key: key, target_name: target.name}
    expect(flash[:scroll_error]).to include("same location")
    expect(ArenaMatch.count).to eq(0)
    expect(@item.reload.quantity).to eq(1)
  end

  it "requires authentication for attack and status and never reveals another player's match" do
    sign_out attacker.user
    post scroll_use_path, params: {action_key: "forged", target_name: target.name}
    expect(response).to redirect_to(new_user_session_path)
    post combat_status_path, as: :json
    expect(response).to have_http_status(:unauthorized)
    sign_in attacker.user
    foreign = create(:arena_match, :live)
    create(:arena_participation, arena_match: foreign, character: target)
    post combat_status_path, params: {character_id: target.id}, as: :json
    expect(response.parsed_body).to include("interrupted" => false, "redirect_url" => nil)
  end

  it "makes the personal Fist Attack purchasable/useable but rejects forged transfer and hides trade controls" do
    attributes = JSON.parse(File.read(Rails.root.join("db/seeds/data/starter_shop.json"))).find { |row| row["key"] == "fist_attack" }
    fist = ItemTemplate.create!(attributes)
    ShopStock.create!(shop_account: account, item_template: fist, current: 10, maximum: 500)
    get shop_path(category: "scrolls")
    buy_offer = WorldActionOffer.find_by!(character: attacker, target: fist, action_type: "shop_buy", status: :offered)
    post buy_shop_path, params: {item_template_id: fist.id, action_key: buy_offer.action_key}
    owned = attacker.inventory.inventory_items.find_by!(item_template: fist)
    expect(attacker.user.currency_wallet.reload.nv_balance).to eq(250)
    get inventory_path(category: "things", subcategory: "scrolls")
    row = Nokogiri::HTML(response.body).at_css("[data-item-id='#{owned.id}']")
    expect(row.text).to include("Use", "Delete")
    expect(row.text).not_to include("Transfer", "Gift", "Sell")
    expect(owned).not_to be_protected_from_discard
    post transfer_item_inventory_path, params: {item_id: owned.id, recipient_name: target.name, quantity: 1}
    expect(owned.reload.inventory.character_id).to eq(attacker.id)
    expect(flash[:alert]).to include("cannot be transferred")
    target.remember_gameplay_context!(name: "shop", params: {category: "scrolls"})
    get inventory_path(scroll_item_id: owned.id)
    key = Nokogiri::HTML(response.body).at_css(".nl-scroll-use input[name='action_key']")["value"]
    post scroll_use_path, params: {action_key: key, target_name: target.name}
    match = ArenaMatch.sole
    get arena_match_path(match)
    expect(response.body).to include("Trauma: <b>80%</b>")
    expect(response.body).to include("started (fist attack)")
    get public_fight_log_path(match)
    expect(response.body).to include("started (fist attack)")
  end

  it "renders recovery polling on Inventory and City without enabling passive NPC attacks there" do
    get inventory_path
    expect(response.body).to include('data-game-layout-encounter-url-value="/combat_status"')
    expect(response.body).not_to include('data-game-layout-encounter-url-value="/world/encounter_check"')
    post combat_status_path, as: :json
    expect(ArenaMatch.count).to eq(0)
  end

  %w[duel_permit_i fist_attack].each do |scroll_key|
    it "renders the #{scroll_key} level rejection once above the item categories and allows reopening Use" do
      acquire_scroll
      template.update!(key: scroll_key, requirements: {"level" => scroll_key == "fist_attack" ? 10 : 5})
      target.update!(level: 5)
      target.remember_gameplay_context!(name: "shop", params: {category: "scrolls"})
      get inventory_path(scroll_item_id: @item.id)
      key = Nokogiri::HTML(response.body).at_css(".nl-scroll-use input[name='action_key']")["value"]

      post scroll_use_path, params: {action_key: key, target_name: target.name}
      expect(response).to redirect_to(inventory_path(category: "things", subcategory: "scrolls"))
      follow_redirect!
      document = Nokogiri::HTML(response.body)
      expect(document.css("[role='alert']").map(&:text)).to eq(["Error using item. Scroll use failed."])
      expect(document.at_css(".nl-inventory-main > :first-child")["class"]).to eq("nl-scroll-error")
      expect(document.at_css(".nl-scroll-use")).to be_nil
      expect(@item.reload.quantity).to eq(1)
      expect(ArenaMatch.count).to eq(0)

      get inventory_path(scroll_item_id: @item.id)
      expect(response.body).not_to include("Error using item. Scroll use failed.")
      expect(Nokogiri::HTML(response.body).at_css(".nl-scroll-use input[name='action_key']")["value"]).to eq(key)
    end
  end
end
