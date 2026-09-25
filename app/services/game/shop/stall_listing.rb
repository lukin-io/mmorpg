# frozen_string_literal: true

module Game
  module Shop
    # Soft-release player-to-player stall lots on a rented Coal Market stall.
    # Reuses AuctionListing rows tagged listed_from=market_stall; applies the
    # rented tier's sale tax as an NV sink on settlement.
    class StallListing
      Result = Struct.new(:success, :message, keyword_init: true)
      LISTED_FROM = "market_stall"

      def self.open_rows
        demand = Array(Game::Seasons::Catalog.active? ? Game::Seasons::Catalog.current["craft_demand_keys"] : []).map(&:to_s)
        rows = AuctionListing.open.not_expired.craft_goods
          .where("auction_listings.metadata->>'listed_from' = ?", LISTED_FROM)
          .includes(:seller_character, :item_template)
          .order(created_at: :desc)
          .limit(50)
          .to_a
        rows.sort_by do |row|
          featured = row.metadata.to_h["featured"] == true ? 0 : 1
          hot = demand.include?(row.item_template.key.to_s) ? 0 : 1
          [featured, hot, -row.created_at.to_i]
        end
      end

      def self.used_mass_for(character)
        AuctionListing.open.not_expired
          .where(seller_character_id: character.id)
          .where("auction_listings.metadata->>'listed_from' = ?", LISTED_FROM)
          .includes(:item_template)
          .sum { |row| row.item_template.weight.to_i * row.quantity.to_i }
      end

      def self.parse_tax_rate(tax)
        raw = tax.to_s.strip
        return BigDecimal("0") if raw.blank?

        pct = raw.delete("%").to_d
        return BigDecimal("0") if pct.negative?

        pct / BigDecimal("100")
      end

      FEATURE_FEE_NV = BigDecimal("12")

      def initialize(character:, inventory_item_id: nil, quantity: 1, price_nv: nil, listing_id: nil, featured: false)
        @character = character
        @inventory_item_id = inventory_item_id
        @quantity = [quantity.to_i, 1].max
        @price_nv = price_nv.to_d
        @listing_id = listing_id
        @featured = ActiveModel::Type::Boolean.new.cast(featured)
      end

      def list!
        lease = StallRent.active_for(character)
        return failure(I18n.t("game.buildings.stall_listing_need_lease")) unless lease

        item = character.inventory&.inventory_items&.find_by(id: inventory_item_id, equipped: false)
        return failure(I18n.t("game.trade_hub.auction_missing_item")) unless item
        unless AuctionListing.listable_template?(item.item_template)
          return failure(I18n.t("game.trade_hub.auction_craft_only"))
        end
        return failure(I18n.t("game.trade_hub.auction_bad_price")) unless price_nv.positive?
        return failure(I18n.t("game.trade_hub.auction_bad_qty")) if quantity > item.quantity

        added_mass = item.item_template.weight.to_i * quantity
        capacity = lease["mass"].to_i
        used = self.class.used_mass_for(character)
        if capacity.positive? && (used + added_mass) > capacity
          return failure(I18n.t("game.buildings.stall_listing_mass_full", used:, capacity:, need: added_mass))
        end

        feature_fee = featured ? FEATURE_FEE_NV : BigDecimal("0")
        wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
        if feature_fee.positive? && wallet.nv_balance.to_d < feature_fee
          return failure(I18n.t("game.buildings.stall_feature_need_nv", amount: feature_fee.to_i))
        end

        ActiveRecord::Base.transaction do
          if feature_fee.positive?
            wallet.adjust!(
              amount: -feature_fee,
              reason: "ashen.stall_feature",
              metadata: {"stall_name" => lease["stall_name"]}
            )
          end
          Game::Inventory::Manager.new(inventory: character.inventory).remove_item!(
            item_template: item.item_template,
            quantity: quantity
          )
          AuctionListing.create!(
            seller_character: character,
            item_template: item.item_template,
            quantity: quantity,
            price_nv: price_nv,
            status: "open",
            metadata: {
              "listed_from" => LISTED_FROM,
              "listed_from_item_id" => item.id,
              "stall_name" => lease["stall_name"],
              "stall_tax" => lease["tax"].to_s,
              "featured" => featured
            }
          )
        end

        msg = featured ? I18n.t("game.buildings.stall_listing_featured") : I18n.t("game.buildings.stall_listing_listed")
        Result.new(success: true, message: msg)
      rescue Game::Inventory::Manager::InventoryUnderflowError => e
        failure(e.message)
      end

      def buy!
        listing = AuctionListing.lock.find_by(id: listing_id, status: "open")
        return failure(I18n.t("game.trade_hub.auction_gone")) unless listing
        return failure(I18n.t("game.trade_hub.auction_gone")) if listing.expired?
        if listing.metadata.to_h["listed_from"].to_s != LISTED_FROM
          return failure(I18n.t("game.trade_hub.auction_gone"))
        end
        if listing.seller_character_id == character.id
          return failure(I18n.t("game.trade_hub.auction_own"))
        end

        buyer_wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
        seller_wallet = listing.seller_character.user.currency_wallet ||
          listing.seller_character.user.create_currency_wallet!(nv_balance: 0)
        price = listing.price_nv.to_d
        if buyer_wallet.nv_balance.to_d < price
          return failure(I18n.t("game.shop.not_enough_nv"))
        end

        tax_rate = self.class.parse_tax_rate(listing.metadata.to_h["stall_tax"])
        tax_rate = seasonal_tax_rate(tax_rate, listing.item_template.key)
        tax = (price * tax_rate).round(2)
        seller_gain = price - tax

        ActiveRecord::Base.transaction do
          buyer_wallet.adjust!(
            amount: -price,
            reason: "ashen.stall_buy",
            metadata: {"listing_id" => listing.id, "tax_nv" => tax.to_s}
          )
          if seller_gain.positive?
            seller_wallet.adjust!(
              amount: seller_gain,
              reason: "ashen.stall_sell",
              metadata: {"listing_id" => listing.id, "tax_nv" => tax.to_s}
            )
          end
          inventory = character.inventory || character.create_inventory!
          Game::Inventory::Manager.new(inventory:).add_item!(
            item_template: listing.item_template,
            quantity: listing.quantity
          )
          listing.update!(status: "sold", buyer_character: character)
        end

        Result.new(success: true, message: I18n.t("game.buildings.stall_listing_bought"))
      end

      private

      attr_reader :character, :inventory_item_id, :quantity, :price_nv, :listing_id, :featured

      def failure(message)
        Result.new(success: false, message:)
      end

      # Mist FOMO: craft-demand mats sell with half stall tax during the season —
      # combat players buy from crafters; merchants keep more NV.
      def seasonal_tax_rate(base_rate, item_key)
        return base_rate unless Game::Seasons::Catalog.active?

        keys = Array(Game::Seasons::Catalog.current["craft_demand_keys"]).map(&:to_s)
        keys.include?(item_key.to_s) ? (base_rate * BigDecimal("0.5")) : base_rate
      end
    end
  end
end
