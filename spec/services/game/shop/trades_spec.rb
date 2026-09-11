# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shop trades" do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }
  let(:character) { create(:character) }
  let(:inventory) { character.inventory }
  let(:wallet) { character.user.currency_wallet }
  let(:city) { create(:zone, location_type: "city") }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:hotspot) { create(:city_hotspot, :shop, zone: city, required_level: 1) }
  let(:template) do
    create(:item_template, key: "trade_penknife", name: "Trade Penknife", slot: "main_hand",
      base_price: 7, weight: 5, stack_limit: 1, durability_max: 10,
      requirements: {"level" => 1, "ap" => 40},
      stat_modifiers: {"damage_min" => 1, "damage_max" => 2, "armor_pierce" => 1},
      enhancement_rules: {"subcategory" => "knives", "shop" => {"sold" => true}, "shop_stock" => {"current" => 5, "max" => 10}})
  end
  let!(:account) { ShopAccount.create!(location: hotspot, nv_balance: 1_000) }
  let!(:stock) { account.shop_stocks.create!(item_template: template, current: 5, maximum: 10) }
  let(:offers) { Game::Shop::TradeOffers.new(character:) }

  before do
    wallet.update!(nv_balance: 100)
    character.remember_gameplay_context!(name: "shop")
  end

  def buy(key, buyer: character, item: template)
    Game::Shop::Purchase.new(character: buyer, item_template: item, action_key: key).call
  end

  def buy_offer(buyer: character, item: template)
    Game::Shop::TradeOffers.new(character: buyer).issue(buy_items: [item]).fetch(:buy).fetch(item.id)
  end

  def sell(key, item:, seller: character)
    Game::Shop::Sale.new(character: seller, inventory_item: item, action_key: key).call
  end

  def sell_offer(item)
    offers.issue(sell_items: [item]).fetch(:sell).fetch(item.id)
  end

  def grant_trading_license(owner = character, expires_at: 3.days.from_now)
    definition = create(:item_template, item_type: "misc", slot: "none", base_price: 300, weight: 1, stack_limit: 1,
      enhancement_rules: {"license" => {"kind" => "trading", "tier" => 1, "duration_days" => 3}})
    permission_offer = WorldActionOffer.create!(character: owner, zone: city, x: 5, y: 5,
      action_type: "shop_buy", status: :completed, target: definition,
      action_key: SecureRandom.hex(16), expires_at: 10.minutes.from_now)
    CharacterLicense.create!(character: owner, item_template: definition, world_action_offer: permission_offer,
      kind: "trading", tier: 1, name: "Trading I", starts_at: 1.minute.ago, expires_at:)
  end

  describe "offered one-item purchases" do
    it "persists one item, exact price/mass/durability, finite stock and a traceable ledger entry" do
      offer = buy_offer
      expect(buy(offer.action_key)).to have_attributes(success: true)

      expect(wallet.reload.nv_balance).to eq(93)
      expect(inventory.reload.current_weight).to eq(5)
      expect(inventory.inventory_items.sole).to have_attributes(quantity: 1, weight: 5, current_durability: 10, max_durability: 10)
      expect(stock.reload.current).to eq(4)
      expect(account.reload.nv_balance).to eq(1_007)
      expect(offer.reload).to be_completed
      ledger = wallet.currency_transactions.sole
      expect(ledger).to have_attributes(amount: -7, balance_after: 93, reason: "shop.purchase")
      expect(ledger.metadata).to include(
        "receipt_version" => 1, "character_id" => character.id,
        "item_template_key" => "trade_penknife", "quantity" => 1,
        "shop_offer_id" => offer.id, "shop_account_id" => account.id, "shop_stock_id" => stock.id,
        "unit_price" => "7.00", "wallet_balance_before" => "100.00", "wallet_balance_after" => "93.00",
        "shop_balance_before" => "1000.00", "shop_balance_after" => "1007.00",
        "shop_stock_before" => 5, "shop_stock_after" => 4,
        "inventory_item_id" => inventory.inventory_items.sole.id,
        "inventory_quantity_before" => 0, "inventory_quantity_after" => 1,
        "inventory_weight_before" => 0, "inventory_weight_after" => 5
      )
      expect(ledger.metadata).not_to have_key("character_license_id")
    end

    it "reuses an unchanged quote without making two live purchase capabilities" do
      original = buy_offer
      expect(buy_offer.id).to eq(original.id)
      expect(WorldActionOffer.offered.where(character:, action_type: "shop_buy").count).to eq(1)
    end

    it "rejects completed replay and offers a fresh key for a deliberate next purchase" do
      original = buy_offer
      expect(buy(original.action_key)).to have_attributes(success: true)
      expect(buy(original.action_key)).not_to have_attributes(success: true)
      fresh = buy_offer
      expect(fresh.id).not_to eq(original.id)
      expect(buy(fresh.action_key)).to have_attributes(success: true)
      expect(wallet.reload.nv_balance).to eq(86)
      expect(inventory.inventory_items.count).to eq(2)
    end

    it "rejects absent, foreign, wrong-target and wrong-action keys" do
      original = buy_offer
      other_character = create(:character)
      create(:character_position, character: other_character, zone: city, x: 5, y: 5)
      other_character.remember_gameplay_context!(name: "shop")
      other_template = create(:item_template)

      expect(buy(nil)).not_to have_attributes(success: true)
      expect(buy(original.action_key, buyer: other_character)).not_to have_attributes(success: true)
      expect(buy(original.action_key, item: other_template)).not_to have_attributes(success: true)
      owned_item = create(:inventory_item, inventory:, item_template: template)
      sale = sell_offer(owned_item)
      expect(buy(sale.action_key)).not_to have_attributes(success: true)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(wallet.currency_transactions).to be_empty
    end

    it "accepts immediately before expiry and rejects at and after expiry" do
      travel_to Time.current.change(usec: 0)
      first = buy_offer
      travel_to first.expires_at - 1.second
      expect(buy(first.action_key)).to have_attributes(success: true)
      second = buy_offer
      travel_to second.expires_at
      expect(buy(second.action_key)).not_to have_attributes(success: true)
      travel_to second.expires_at + 1.second
      expect(buy(second.action_key)).not_to have_attributes(success: true)
      expect(wallet.currency_transactions.count).to eq(1)
    end

    it "rejects changed price or item properties instead of charging an unseen quote" do
      original = buy_offer
      template.update!(base_price: 8)

      expect(buy(original.action_key).message).to include("changed")
      expect(wallet.reload.nv_balance).to eq(100)
      expect(inventory.inventory_items).to be_empty
      expect(original.reload).to be_offered
    end

    it "rejects removed catalog eligibility even with a previously offered key" do
      original = buy_offer
      template.update!(enhancement_rules: template.enhancement_rules.except("shop"))
      expect(buy(original.action_key).message).to include("cannot be bought")
      expect(wallet.reload.nv_balance).to eq(100)
    end

    it "rechecks fresh stock without invalidating another customer's unchanged price" do
      original = buy_offer
      stock.update!(current: 0)
      expect(buy(original.action_key).message).to eq("Out of stock.")
      expect(wallet.reload.nv_balance).to eq(100)
      expect(inventory.inventory_items).to be_empty
      expect(original.reload).to be_offered
    end

    it "rolls back money, ledger, stock and capability when carrying capacity is exceeded" do
      inventory.update!(current_weight: inventory.max_weight)
      original = buy_offer
      result = nil
      character.with_lock { result = buy(original.action_key) }

      expect(result).not_to have_attributes(success: true)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(wallet.currency_transactions).to be_empty
      expect(inventory.inventory_items).to be_empty
      expect(stock.reload.current).to eq(5)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(original.reload).to be_offered
    end

    it "rejects changed funds and retains the unconsumed offer" do
      original = buy_offer
      wallet.update!(nv_balance: 6)
      expect(buy(original.action_key).message).to eq("Not enough NV.")
      expect(wallet.reload.nv_balance).to eq(6)
      expect(wallet.currency_transactions).to be_empty
      expect(inventory.inventory_items).to be_empty
      expect(original.reload).to be_offered
    end

    it "rejects the shop balance storage ceiling before any transfer and accepts its last fractional headroom" do
      account.update!(nv_balance: ShopAccount::NV_LIMIT - 7)
      original = buy_offer
      expect(buy(original.action_key)).to have_attributes(success: false,
        message: "The Shop cannot receive this payment right now.")
      expect(wallet.reload.nv_balance).to eq(100)
      expect(account.reload.nv_balance).to eq(ShopAccount::NV_LIMIT - 7)
      expect(stock.reload.current).to eq(5)
      expect(inventory.reload.current_weight).to eq(0)
      expect(inventory.inventory_items).to be_empty
      expect(wallet.currency_transactions).to be_empty
      expect(original.reload).to be_offered

      account.update!(nv_balance: ShopAccount::NV_LIMIT - BigDecimal("7.01"))
      expect(buy(original.action_key)).to have_attributes(success: true)
      expect(account.reload.nv_balance).to eq(ShopAccount::NV_LIMIT - BigDecimal("0.01"))
      expect(wallet.reload.nv_balance).to eq(93)
    end

    it "allows buying when equipment requirements are unmet" do
      template.update!(requirements: {"level" => 99, "strength" => 999})
      expect(buy(buy_offer.action_key)).to have_attributes(success: true)
    end

    it "rejects another shop location and an obsolete building revision" do
      original = buy_offer
      second_city = create(:zone, location_type: "city")
      create(:city_hotspot, :shop, zone: second_city, required_level: 1)
      position.update!(zone: second_city)
      expect(buy(original.action_key)).not_to have_attributes(success: true)
      position.update!(zone: city)
      hotspot.touch
      expect(buy(original.action_key)).not_to have_attributes(success: true)
      expect(wallet.currency_transactions).to be_empty
    end

    it "rejects a closed shop and leaving the shop room" do
      original = buy_offer
      character.remember_gameplay_context!(name: "world")
      expect(buy(original.action_key)).not_to have_attributes(success: true)
      character.remember_gameplay_context!(name: "shop")
      hotspot.update!(active: false)
      expect(buy(original.action_key)).not_to have_attributes(success: true)
      expect(wallet.currency_transactions).to be_empty
    end

    it "rolls back inventory and debit if final offer consumption fails" do
      original = buy_offer
      allow_any_instance_of(WorldActionOffer).to receive(:complete!).and_raise(ActiveRecord::RecordInvalid)
      expect { buy(original.action_key) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(inventory.reload.current_weight).to eq(0)
      expect(inventory.inventory_items).to be_empty
      expect(stock.reload.current).to eq(5)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(original.reload).to be_offered
    end

    it "rolls back acquired goods and debit when the ledger cannot be persisted" do
      original = buy_offer
      allow_any_instance_of(CurrencyTransaction).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      character.with_lock do
        expect { buy(original.action_key) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      expect(wallet.reload.nv_balance).to eq(100)
      expect(inventory.reload.current_weight).to eq(0)
      expect(inventory.inventory_items).to be_empty
      expect(stock.reload.current).to eq(5)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(wallet.currency_transactions).to be_empty
      expect(original.reload).to be_offered
    end
  end

  describe "offered sales" do
    let!(:item) { create(:inventory_item, inventory:, item_template: template, quantity: 2, weight: 5, properties: {"current_durability" => 5}) }

    before do
      inventory.update!(current_weight: 10)
      grant_trading_license
    end

    it "sells one unit at the displayed durability-adjusted price and rejects replay" do
      original = sell_offer(item)
      expect(sell(original.action_key, item:)).to have_attributes(success: true)
      expect(sell(original.action_key, item:)).not_to have_attributes(success: true)
      expect(item.reload.quantity).to eq(1)
      expect(inventory.reload.current_weight).to eq(5)
      expect(wallet.reload.nv_balance).to eq(BigDecimal("100.7"))
      expect(stock.reload.current).to eq(6)
      expect(account.reload.nv_balance).to eq(BigDecimal("999.30"))
      expect(wallet.currency_transactions.sole.metadata).to include(
        "receipt_version" => 1, "character_id" => character.id,
        "item_template_key" => "trade_penknife", "quantity" => 1,
        "shop_offer_id" => original.id, "shop_account_id" => account.id, "shop_stock_id" => stock.id,
        "unit_price" => "0.70", "base_price" => "7.00",
        "wallet_balance_before" => "100.00", "wallet_balance_after" => "100.70",
        "shop_balance_before" => "1000.00", "shop_balance_after" => "999.30",
        "shop_stock_before" => 5, "shop_stock_after" => 6,
        "inventory_item_id" => item.id, "inventory_quantity_before" => 2, "inventory_quantity_after" => 1,
        "inventory_weight_before" => 10, "inventory_weight_after" => 5
      )
    end

    it "rejects changed durability instead of crediting the stale quoted price" do
      original = sell_offer(item)
      stale_item = InventoryItem.find(item.id)
      item.update!(properties: {"current_durability" => 1})
      result = sell(original.action_key, item: stale_item)

      expect(result.message).to include("changed")
      expect(wallet.reload.nv_balance).to eq(100)
      expect(item.reload.quantity).to eq(2)
      expect(original.reload).to be_offered
    end

    it "rejects impossible durability after a template maximum correction without repairing the item" do
      original = sell_offer(item)
      template.update!(durability_max: 4)
      original_item_state = item.reload.attributes
      result = sell(original.action_key, item:)

      expect(result.message).to include("invalid durability")
      expect(wallet.reload.nv_balance).to eq(100)
      expect(wallet.currency_transactions).to be_empty
      expect(item.reload.attributes).to eq(original_item_state)
      expect(original.reload).to be_offered
      expect(offers.issue(sell_items: [item]).fetch(:sell)).to be_empty
    end

    it "rejects quantity, protection and ownership changed after rendering" do
      original = sell_offer(item)
      stale_item = InventoryItem.find(item.id)
      item.update!(bound: true)
      expect(sell(original.action_key, item: stale_item).message).to include("cannot be sold")
      item.update!(bound: false, quantity: 1)
      expect(sell(original.action_key, item: stale_item).message).to include("changed")
      foreign_inventory = create(:character).inventory
      item.update!(inventory: foreign_inventory)
      expect(sell(original.action_key, item: stale_item)).not_to have_attributes(success: true)
      expect(wallet.currency_transactions).to be_empty
    end

    it "rejects inventory-only items without an authored stock record" do
      stock.destroy!
      template.update!(enhancement_rules: {"subcategory" => "knives"})
      expect(sell(sell_offer(item).action_key, item:)).to have_attributes(success: false)
      expect(template.reload.shop_stock).to eq({})
      expect(item.reload.quantity).to eq(2)
      expect(wallet.reload.nv_balance).to eq(100)
    end

    it "rejects a missing or expired license without changing any economic state" do
      offer = sell_offer(item)
      CharacterLicense.where(character:).update_all(expires_at: Time.current)
      expect(sell(offer.action_key, item:).message).to include("trading license")
      expect(item.reload.quantity).to eq(2)
      expect(inventory.reload.current_weight).to eq(10)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(stock.reload.current).to eq(5)
      expect(offer.reload).to be_offered
    end

    it "accepts immediately before license expiry but rejects at its deadline" do
      license = CharacterLicense.find_by!(character:)
      offer = sell_offer(item)
      travel_to license.expires_at - 1.second
      # A new short-lived offer must be rendered close to license expiry.
      offer = sell_offer(item)
      expect(sell(offer.action_key, item:)).to have_attributes(success: true)
      offer = sell_offer(item)
      travel_to license.expires_at, with_usec: true
      expect(sell(offer.action_key, item:).message).to include("trading license")
      expect(wallet.reload.nv_balance).to eq(BigDecimal("100.70"))
    end

    it "rejects full stock instead of silently destroying the incoming unit" do
      stock.update!(current: 9)
      first = sell_offer(item)
      expect(sell(first.action_key, item:)).to have_attributes(success: true)
      expect(stock.reload.current).to eq(10)
      second = sell_offer(item)
      expect(sell(second.action_key, item:).message).to include("enough of this item")
      expect(stock.reload.current).to eq(10)
      expect(item.reload.quantity).to eq(1)
      expect(wallet.reload.nv_balance).to eq(BigDecimal("100.70"))
      expect(second.reload).to be_offered
    end

    it "rejects uncaptured capacity and insufficient shop funds, including after the quote" do
      original = sell_offer(item)
      stock.update!(maximum: nil)
      expect(sell(original.action_key, item:)).to have_attributes(success: false)
      stock.update!(maximum: 10)
      account.update!(nv_balance: BigDecimal("0.69"))
      expect(sell(original.action_key, item:).message).to include("enough NV")
      expect(item.reload.quantity).to eq(2)
      expect(stock.reload.current).to eq(5)
      expect(wallet.currency_transactions).to be_empty
      account.update!(nv_balance: BigDecimal("0.70"))
      expect(sell(original.action_key, item:)).to have_attributes(success: true)
      expect(account.reload.nv_balance).to eq(0)
    end

    it "requotes changed proficiency and settles the published higher rate" do
      original = sell_offer(item)
      character.update!(metadata: character.metadata.merge("profession_skills" => {"trading" => 600}))
      expect(sell(original.action_key, item:).message).to include("changed")
      expect(sell(sell_offer(item).action_key, item:)).to have_attributes(success: true)
      expect(wallet.reload.nv_balance).to eq(BigDecimal("102.45"))
      expect(account.reload.nv_balance).to eq(BigDecimal("997.55"))
      expect(wallet.currency_transactions.sole.metadata).to include("trading_skill" => 600,
        "shop_stock_before" => 5, "shop_stock_after" => 6)
    end

    it "rolls back item removal, both balances and stock if offer completion fails" do
      original = sell_offer(item)
      allow_any_instance_of(WorldActionOffer).to receive(:complete!).and_raise(ActiveRecord::RecordInvalid)
      expect { sell(original.action_key, item:) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(item.reload.quantity).to eq(2)
      expect(inventory.reload.current_weight).to eq(10)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(stock.reload.current).to eq(5)
      expect(wallet.currency_transactions).to be_empty
      expect(original.reload).to be_offered
    end

    it "restores the sold item and all economic state when the ledger cannot be persisted" do
      item.update!(quantity: 1)
      inventory.update!(current_weight: 5)
      original = sell_offer(item)
      allow_any_instance_of(CurrencyTransaction).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      character.with_lock do
        expect { sell(original.action_key, item:) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      expect(item.reload.quantity).to eq(1)
      expect(inventory.reload.current_weight).to eq(5)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(stock.reload.current).to eq(5)
      expect(wallet.currency_transactions).to be_empty
      expect(original.reload).to be_offered
    end
  end

  describe "offered license purchases" do
    let!(:license_template) do
      create(:item_template, item_type: "misc", slot: "none", base_price: 300, weight: 1, stack_limit: 1,
        enhancement_rules: {"subcategory" => "misc", "shop" => {"sold" => true, "mode" => "licenses"},
          "license" => {"kind" => "trading", "tier" => 1, "duration_days" => 3, "required_perk" => "merchant"}})
    end
    let!(:license_stock) { account.shop_stocks.create!(item_template: license_template, current: 9) }

    before do
      wallet.update!(nv_balance: 1_000)
      character.update!(perks: {"merchant" => true}, metadata: character.metadata.merge("profession_unlocks" => {"merchant" => true}))
    end

    it "buys one timed permission atomically and does not create an inventory item or mass" do
      travel_to Time.current.change(usec: 0)
      inventory.update!(current_weight: inventory.max_weight)
      original_weight = inventory.current_weight
      original = buy_offer(item: license_template)
      expect(buy(original.action_key, item: license_template)).to have_attributes(success: true)
      expect(CharacterLicense.where(character:).sole).to have_attributes(kind: "trading", tier: 1,
        starts_at: Time.current, expires_at: 3.days.from_now, world_action_offer: original)
      expect(inventory.inventory_items).to be_empty
      expect(inventory.reload.current_weight).to eq(original_weight)
      expect(wallet.reload.nv_balance).to eq(700)
      expect(account.reload.nv_balance).to eq(1_300)
      expect(license_stock.reload.current).to eq(8)
      expect(original.reload).to be_completed
      expect(buy(original.action_key, item: license_template)).to have_attributes(success: false)
      expect(CharacterLicense.where(character:).count).to eq(1)
      expect(wallet.currency_transactions.count).to eq(1)
      expect(wallet.currency_transactions.sole.metadata).to include(
        "character_license_id" => CharacterLicense.where(character:).sole.id,
        "inventory_weight_before" => original_weight, "inventory_weight_after" => original_weight,
        "unit_price" => "300.00", "wallet_balance_before" => "1000.00", "wallet_balance_after" => "700.00",
        "shop_balance_before" => "1000.00", "shop_balance_after" => "1300.00",
        "shop_stock_before" => 9, "shop_stock_after" => 8
      )
      expect(wallet.currency_transactions.sole.metadata).not_to have_key("inventory_item_id")
    end

    it "rejects missing prerequisites and revalidates them after an offer was issued" do
      original = buy_offer(item: license_template)
      character.update!(perks: {})
      expect(buy(original.action_key, item: license_template).message).to include("Merchant perk")
      expect(offers.issue(buy_items: [license_template]).fetch(:buy)).to be_empty
      expect(CharacterLicense.where(character:)).to be_empty
      expect(wallet.reload.nv_balance).to eq(1_000)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(license_stock.reload.current).to eq(9)
    end

    it "rolls back debit, permission and stock together when final consumption fails" do
      original = buy_offer(item: license_template)
      allow_any_instance_of(WorldActionOffer).to receive(:complete!).and_raise(ActiveRecord::RecordInvalid)
      expect { buy(original.action_key, item: license_template) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(CharacterLicense.where(character:)).to be_empty
      expect(wallet.reload.nv_balance).to eq(1_000)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(license_stock.reload.current).to eq(9)
      expect(wallet.currency_transactions).to be_empty
      expect(original.reload).to be_offered
    end

    it "rejects an overlapping license kind even when another tier was already offered" do
      other = create(:item_template, item_type: "misc", slot: "none", base_price: 800, weight: 1, stack_limit: 1,
        enhancement_rules: {"shop" => {"sold" => true, "mode" => "licenses"},
          "license" => {"kind" => "trading", "tier" => 2, "duration_days" => 10, "required_perk" => "merchant"}})
      other_stock = account.shop_stocks.create!(item_template: other, current: 666)
      offered = offers.issue(buy_items: [license_template, other]).fetch(:buy)
      expect(buy(offered.fetch(license_template.id).action_key, item: license_template)).to have_attributes(success: true)

      second_offer = offered.fetch(other.id)
      expect(buy(second_offer.action_key, item: other).message).to include("already have an active trading license")
      expect(CharacterLicense.where(character:).count).to eq(1)
      expect(wallet.reload.nv_balance).to eq(700)
      expect(account.reload.nv_balance).to eq(1_300)
      expect(other_stock.reload.current).to eq(666)
      expect(second_offer.reload).to be_offered
      expect(offers.issue(buy_items: [license_template, other]).fetch(:buy)).to be_empty
      expect(Game::Shop::LicenseRules.new(character:).purchase_block_reason(other)).to include("already have an active trading license")
    end
  end

  context "concurrent trades", js: true do
    def another_customer
      customer = create(:character)
      create(:character_position, character: customer, zone: city, x: 5, y: 5)
      customer.remember_gameplay_context!(name: "shop")
      customer.user.currency_wallet.update!(nv_balance: 100)
      customer
    end

    def trade_after_waiting_for_wallet(deadline:, &operation)
      locked = Queue.new
      release = Queue.new
      requested = Queue.new
      results = Queue.new
      allow_any_instance_of(CurrencyWallet).to receive(:lock!).and_wrap_original do |original, *args|
        requested << true if Thread.current[:shop_wallet_wait]
        original.call(*args)
      end

      holder = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          CurrencyWallet.find(wallet.id).with_lock do
            locked << true
            release.pop
          end
        end
      end
      Timeout.timeout(5) { locked.pop }
      worker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Thread.current[:shop_wallet_wait] = true
          results << operation.call
        rescue => error
          results << error
        ensure
          Thread.current[:shop_wallet_wait] = nil
        end
      end
      Timeout.timeout(5) { requested.pop }
      # The first offer check has passed; a different DB connection still owns
      # the wallet row. Advance the server clock before releasing that lock.
      travel_to deadline, with_usec: true
      release << true
      expect(holder.join(5)).to eq(holder)
      expect(worker.join(5)).to eq(worker)
      results.pop
    ensure
      release << true
      [holder, worker].compact.each do |thread|
        thread.kill if thread.alive?
        thread.join
      end
    end

    def concurrently(inputs, &operation)
      gate = Queue.new
      results = Queue.new
      threads = inputs.map do |input|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            gate.pop
            results << operation.call(input)
          rescue => error
            results << error
          end
        end
      end
      inputs.size.times { gate << true }
      threads.each { |thread| expect(thread.join(10)).to eq(thread) }
      inputs.size.times.map { results.pop }
    end

    it "commits one purchase for simultaneous submissions of the same offer" do
      original = buy_offer
      results = concurrently([original.action_key, original.action_key]) do |key|
        buy(key, buyer: Character.find(character.id), item: ItemTemplate.find(template.id))
      end
      expect(results.count { |result| result.is_a?(Game::Shop::Purchase::Result) && result.success }).to eq(1)
      expect(wallet.reload.nv_balance).to eq(93)
      expect(inventory.inventory_items.sum(:quantity)).to eq(1)
      expect(wallet.currency_transactions.count).to eq(1)
    end

    it "serializes different customers competing for the last stock unit" do
      stock.update!(current: 1)
      other = create(:character)
      create(:character_position, character: other, zone: city, x: 5, y: 5)
      other.remember_gameplay_context!(name: "shop")
      other.user.currency_wallet.update!(nv_balance: 100)
      inputs = [[character.id, buy_offer.action_key], [other.id, buy_offer(buyer: other).action_key]]
      results = concurrently(inputs) do |id, key|
        buy(key, buyer: Character.find(id), item: ItemTemplate.find(template.id))
      end
      expect(results.count { |result| result.is_a?(Game::Shop::Purchase::Result) && result.success }).to eq(1)
      expect(stock.reload.current).to eq(0)
      expect(InventoryItem.where(item_template: template).sum(:quantity)).to eq(1)
      expect(CurrencyTransaction.where(reason: "shop.purchase").count).to eq(1)
    end

    it "preserves both stock increments from different customers selling the same template" do
      first_item = create(:inventory_item, inventory:, item_template: template, weight: 5)
      inventory.update!(current_weight: 5)
      other = create(:character)
      create(:character_position, character: other, zone: city, x: 5, y: 5)
      other.remember_gameplay_context!(name: "shop")
      other_item = create(:inventory_item, inventory: other.inventory, item_template: template, weight: 5)
      other.inventory.update!(current_weight: 5)
      grant_trading_license
      grant_trading_license(other)
      first_key = sell_offer(first_item).action_key
      other_key = Game::Shop::TradeOffers.new(character: other).issue(sell_items: [other_item]).fetch(:sell).fetch(other_item.id).action_key
      inputs = [[character.id, first_item.id, first_key], [other.id, other_item.id, other_key]]
      results = concurrently(inputs) do |id, item_id, key|
        sell(key, item: InventoryItem.find(item_id), seller: Character.find(id))
      end
      expect(results).to all(be_a(Game::Shop::Sale::Result))
      expect(results).to all(have_attributes(success: true))
      expect(stock.reload.current).to eq(7)
      expect(CurrencyTransaction.where(reason: "shop.sale").count).to eq(2)
    end

    it "settles one sale for concurrent submissions of the same offered item" do
      item = create(:inventory_item, inventory:, item_template: template, weight: 5)
      inventory.update!(current_weight: 5)
      grant_trading_license
      original = sell_offer(item)
      inputs = 2.times.map { [Character.find(character.id), InventoryItem.find(item.id)] }
      results = concurrently(inputs) do |seller, offered_item|
        sell(original.action_key, item: offered_item, seller:)
      end
      expect(results).to all(be_a(Game::Shop::Sale::Result))
      expect(results.count { |result| result.is_a?(Game::Shop::Sale::Result) && result.success }).to eq(1)
      expect(InventoryItem.exists?(item.id)).to be(false)
      expect(wallet.reload.nv_balance).to eq(BigDecimal("101.40"))
      expect(account.reload.nv_balance).to eq(BigDecimal("998.60"))
      expect(stock.reload.current).to eq(6)
      expect(wallet.currency_transactions.count).to eq(1)
    end

    it "conserves NV, stock and items across a concurrent purchase and sale with ordered receipts" do
      seller = another_customer
      sold_item = create(:inventory_item, inventory: seller.inventory, item_template: template, weight: 5)
      seller.inventory.update!(current_weight: 5)
      grant_trading_license(seller)
      purchase_offer = buy_offer
      sale_offer = Game::Shop::TradeOffers.new(character: seller).issue(sell_items: [sold_item]).fetch(:sell).fetch(sold_item.id)

      results = concurrently([:buy, :sell]) do |action|
        if action == :buy
          buy(purchase_offer.action_key, buyer: Character.find(character.id), item: ItemTemplate.find(template.id))
        else
          sell(sale_offer.action_key, item: InventoryItem.find(sold_item.id), seller: Character.find(seller.id))
        end
      end

      expect(results).to all(have_attributes(success: true))
      expect(wallet.reload.nv_balance).to eq(93)
      expect(seller.user.currency_wallet.reload.nv_balance).to eq(BigDecimal("101.40"))
      expect(account.reload.nv_balance).to eq(BigDecimal("1005.60"))
      expect(wallet.nv_balance + seller.user.currency_wallet.nv_balance + account.nv_balance).to eq(1_200)
      expect(stock.reload.current).to eq(5)
      expect(InventoryItem.where(item_template: template).sum(:quantity)).to eq(1)
      expect(inventory.reload.current_weight + seller.inventory.reload.current_weight).to eq(5)
      expect(InventoryItem.exists?(sold_item.id)).to be(false)

      receipts = CurrencyTransaction.where(reason: %w[shop.purchase shop.sale]).order(:id).to_a
      expect(receipts.size).to eq(2)
      expect(receipts.sum(&:amount)).to eq(BigDecimal("-5.60"))
      expect(receipts.map { |receipt| receipt.metadata.fetch("shop_offer_id") }).to contain_exactly(purchase_offer.id, sale_offer.id)
      expect(receipts.first.metadata.fetch("shop_balance_before")).to eq("1000.00")
      expect(receipts.first.metadata.fetch("shop_balance_after")).to eq(receipts.last.metadata.fetch("shop_balance_before"))
      expect(receipts.last.metadata.fetch("shop_balance_after")).to eq("1005.60")
      expect(receipts.first.metadata.fetch("shop_stock_after")).to eq(receipts.last.metadata.fetch("shop_stock_before"))
    end

    ["funds", "stock headroom"].each do |scarce_resource|
      it "settles only one of two sellers competing for the Shop's final #{scarce_resource}" do
        other = another_customer
        first_item = create(:inventory_item, inventory:, item_template: template, weight: 5)
        other_item = create(:inventory_item, inventory: other.inventory, item_template: template, weight: 5)
        inventory.update!(current_weight: 5)
        other.inventory.update!(current_weight: 5)
        grant_trading_license
        grant_trading_license(other)
        if scarce_resource == "funds"
          account.update!(nv_balance: BigDecimal("1.40"))
        else
          stock.update!(current: 9)
        end
        funds_before = account.nv_balance
        stock_before = stock.current
        first_offer = sell_offer(first_item)
        second_offer = Game::Shop::TradeOffers.new(character: other).issue(sell_items: [other_item]).fetch(:sell).fetch(other_item.id)
        inputs = [[character.id, first_item.id, first_offer.action_key], [other.id, other_item.id, second_offer.action_key]]

        results = concurrently(inputs) do |id, item_id, key|
          sell(key, item: InventoryItem.find(item_id), seller: Character.find(id))
        end

        expect(results).to all(be_a(Game::Shop::Sale::Result))
        expect(results.count(&:success)).to eq(1)
        expect(account.reload.nv_balance).to eq(funds_before - BigDecimal("1.40"))
        expect(stock.reload.current).to eq(stock_before + 1)
        expect(wallet.reload.nv_balance + other.user.currency_wallet.reload.nv_balance).to eq(BigDecimal("201.40"))
        expect(InventoryItem.where(item_template: template).sum(:quantity)).to eq(1)
        expect(inventory.reload.current_weight + other.inventory.reload.current_weight).to eq(5)
        expect(CurrencyTransaction.where(reason: "shop.sale").count).to eq(1)
        expect(WorldActionOffer.where(id: [first_offer.id, second_offer.id]).completed.count).to eq(1)
        expect(WorldActionOffer.where(id: [first_offer.id, second_offer.id]).offered.count).to eq(1)
      end
    end

    it "rejects a purchase whose offer expires while it waits for the wallet lock" do
      original = buy_offer
      result = trade_after_waiting_for_wallet(deadline: original.expires_at) do
        buy(original.action_key, buyer: Character.find(character.id), item: ItemTemplate.find(template.id))
      end

      expect(result).to have_attributes(success: false, message: "Shop action is no longer available. Refresh the shop.")
      expect(wallet.reload.nv_balance).to eq(100)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(stock.reload.current).to eq(5)
      expect(inventory.reload.current_weight).to eq(0)
      expect(inventory.inventory_items).to be_empty
      expect(wallet.currency_transactions).to be_empty
      expect(original.reload).to be_offered
    end

    it "rejects a sale whose offer expires while it waits for the wallet lock" do
      item = create(:inventory_item, inventory:, item_template: template, weight: 5)
      inventory.update!(current_weight: 5)
      grant_trading_license
      original = sell_offer(item)
      result = trade_after_waiting_for_wallet(deadline: original.expires_at) do
        sell(original.action_key, item: InventoryItem.find(item.id), seller: Character.find(character.id))
      end

      expect(result).to have_attributes(success: false, message: "Shop action is no longer available. Refresh the shop.")
      expect(item.reload.quantity).to eq(1)
      expect(inventory.reload.current_weight).to eq(5)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(account.reload.nv_balance).to eq(1_000)
      expect(stock.reload.current).to eq(5)
      expect(wallet.currency_transactions).to be_empty
      expect(original.reload).to be_offered
    end
  end
end
