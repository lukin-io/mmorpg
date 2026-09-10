# frozen_string_literal: true

module Game
  module Shop
    # Reads the explicitly authored Shop assortment and an owned inventory.
    # Inputs are a character, the resolved Shop account, and optional filters.
    # Returns bounded template rows or filtered inventory rows without mutations.
    class Catalog
      MODES = [
        ["buy", "Buy Goods"],
        ["licenses", "Licenses"],
        ["sell", "Sell Goods"],
        ["novice", "For Beginners"]
      ].freeze

      CATEGORIES = [
        ["knives", "Knives"],
        ["swords", "Swords"],
        ["axes", "Axes"],
        ["blunt", "Blunt"],
        ["polearms", "Halberds & Spears"],
        ["staves", "Staves"],
        ["shields", "Shields"],
        ["armor", "Armor"],
        ["helmets", "Helmets"],
        ["boots", "Boots"],
        ["pants", "Pants"],
        ["belts", "Belts"],
        ["gloves", "Gloves"],
        ["bracers", "Bracers"],
        ["jewelry", "Jewelry"],
        ["relics", "Relics"],
        ["scrolls", "Scrolls & Potions"],
        ["runes", "Runes"],
        ["misc", "Other"]
      ].freeze
      VALID_MODES = MODES.map(&:first).freeze
      VALID_CATEGORIES = CATEGORIES.map(&:first).freeze
      MAX_CATALOG_ROWS = 200
      FILTER_DEFAULTS = {min_level: 0, max_level: 33, min_price: 0, max_price: 1_000_000}.freeze

      attr_reader :character, :shop_account, :params

      def initialize(character:, shop_account: nil, params: {})
        @character = character
        @shop_account = shop_account
        allowed_params = params.respond_to?(:permit) ? params.permit(:mode, :category, :min_level, :max_level, :min_price, :max_price) : params
        @params = allowed_params.to_h.with_indifferent_access
      end

      def mode
        value = params[:mode].presence || "buy"
        VALID_MODES.include?(value) ? value : "buy"
      end

      def category
        value = params[:category].presence || "knives"
        VALID_CATEGORIES.include?(value) ? value : "knives"
      end

      def filters
        @filters ||= FILTER_DEFAULTS.to_h do |key, default|
          value = params[key].to_s
          [key, value.match?(/\A\d{1,7}\z/) ? value.to_i : default]
        end
      end

      def items
        return [] unless shop_account && %w[buy licenses].include?(mode)

        scope = self.class.buyable_scope.where(id: shop_account.shop_stocks.select(:item_template_id))
          .where("COALESCE(enhancement_rules -> 'shop' ->> 'mode', 'buy') = ?", mode)
        if mode == "licenses"
          scope.order(Arel.sql("enhancement_rules -> 'shop' ->> 'position'"), :id)
            .limit(MAX_CATALOG_ROWS).select(&:available_in_shop?)
        else
          scope = scope.where("enhancement_rules ->> 'subcategory' = ?", category)
          filter_scope(scope).order(:base_price, :name, :id).limit(MAX_CATALOG_ROWS).select(&:available_in_shop?)
        end
      end

      def sell_items(inventory, loaded_items: nil)
        return [] unless shop_account && mode == "sell"

        rows = loaded_items || inventory.inventory_items.includes(:item_template).to_a
        rows.select do |item|
          template = item.item_template
          self.class.category_for(template) == category && matches_filters?(template)
        end.sort_by { |item| [item.slot_index.to_i, item.id.to_i] }
      end

      def self.sale_price(template, trading_skill: 0)
        ResalePrice.new(base_price: template.base_price, trading_skill:).amount
      end

      def self.sale_price_for_item(item, trading_skill: 0)
        ResalePrice.new(base_price: item.item_template.base_price, trading_skill:,
          current_durability: item.current_durability, max_durability: item.max_durability).amount
      end

      def self.required_level(template)
        template.requirements.to_h["level"].to_i
      end

      def self.category_for(template)
        subcategory = template.inventory_subcategory
        return "scrolls" if subcategory == "potions"

        VALID_CATEGORIES.include?(subcategory) ? subcategory : "misc"
      end

      def self.buyable_scope
        ItemTemplate.where("base_price > 0")
          .where("enhancement_rules @> ?", {shop: {sold: true}}.to_json)
          .where("enhancement_rules ->> 'subcategory' IN (?)", VALID_CATEGORIES)
      end

      def self.buyable_template(id)
        template = buyable_scope.find_by(id:)
        template if template&.available_in_shop?
      end

      private

      def filter_scope(scope)
        # CASE keeps legacy/malformed JSON from raising a PostgreSQL cast error.
        scope.where(
          "CASE WHEN requirements ->> 'level' ~ '^[0-9]+$' THEN (requirements ->> 'level')::numeric ELSE 0 END BETWEEN ? AND ?",
          filters.fetch(:min_level), filters.fetch(:max_level)
        ).where(base_price: filters.fetch(:min_price)..filters.fetch(:max_price))
      end

      def matches_filters?(template)
        level = self.class.required_level(template)
        price = template.base_price.to_d
        level.between?(filters[:min_level], filters[:max_level]) &&
          price.between?(filters[:min_price], filters[:max_price])
      end
    end
  end
end
