# frozen_string_literal: true

module Game
  module Shop
    # Server-authored shop catalog for the city shop frame.
    class Catalog
      MODES = [
        ["buy", "Buy"],
        ["licenses", "Licenses"],
        ["sell", "Sell"],
        ["novice", "Novice"]
      ].freeze

      CATEGORIES = [
        ["all", "All"],
        ["weapons", "Weapons"],
        ["armor", "Armor"],
        ["jewelry", "Jewelry"],
        ["consumables", "Elixirs"],
        ["materials", "Resources"],
        ["misc", "Misc"]
      ].freeze

      WEAPON_SLOTS = %w[main_hand].freeze
      ARMOR_SLOTS = %w[head chest legs feet hands bracers off_hand].freeze
      JEWELRY_SLOTS = %w[amulet ring_1 ring_2 ring_3 ring_4 relic].freeze
      VALID_MODES = MODES.map(&:first).freeze
      VALID_CATEGORIES = CATEGORIES.map(&:first).freeze

      attr_reader :character, :params

      def initialize(character:, params: {})
        @character = character
        @params = params
      end

      def mode
        value = params[:mode].presence || "buy"
        VALID_MODES.include?(value) ? value : "buy"
      end

      def category
        value = params[:category].presence || "all"
        VALID_CATEGORIES.include?(value) ? value : "all"
      end

      def items
        base_scope.order(:item_type, :slot, :base_price, :name).to_a
          .select { |template| matches_mode?(template) }
          .select { |template| matches_category?(template) }
          .select { |template| matches_level_filter?(template) }
      end

      def sell_items(inventory)
        inventory.inventory_items.includes(:item_template).order(:slot_index, :id).to_a
      end

      def self.sale_price(template)
        base_price = template.base_price.to_i
        return 0 unless base_price.positive?

        [(base_price / 2.0).ceil, 1].max
      end

      def self.required_level(template)
        template.requirements.to_h["level"].to_i
      end

      def self.category_for(template)
        case template.item_type
        when "equipment"
          return "weapons" if WEAPON_SLOTS.include?(template.slot)
          return "armor" if ARMOR_SLOTS.include?(template.slot)
          return "jewelry" if JEWELRY_SLOTS.include?(template.slot)

          "misc"
        when "consumable"
          "consumables"
        when "material"
          "materials"
        else
          "misc"
        end
      end

      def self.buyable_template(id)
        ItemTemplate.where("base_price > 0").find_by(id:)
      end

      private

      def base_scope
        ItemTemplate.where("base_price > 0")
      end

      def matches_mode?(template)
        case mode
        when "licenses"
          license?(template)
        when "novice"
          required_level = self.class.required_level(template)
          required_level <= 5 && template.base_price.to_i <= 250
        when "sell"
          false
        else
          !license?(template)
        end
      end

      def matches_category?(template)
        category == "all" || self.class.category_for(template) == category
      end

      def matches_level_filter?(template)
        required_level = self.class.required_level(template)
        min_level = params[:min_level].to_i if params[:min_level].present?
        max_level = params[:max_level].to_i if params[:max_level].present?
        min_price = params[:min_price].to_i if params[:min_price].present?
        max_price = params[:max_price].to_i if params[:max_price].present?

        return false if min_level && required_level < min_level
        return false if max_level && required_level > max_level
        return false if min_price && template.base_price.to_i < min_price
        return false if max_price && template.base_price.to_i > max_price

        true
      end

      def license?(template)
        key = template.key.to_s.downcase
        name = template.name.to_s.downcase
        key.start_with?("license") || name.include?("license")
      end
    end
  end
end
