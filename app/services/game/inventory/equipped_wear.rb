# frozen_string_literal: true

module Game
  module Inventory
    # Counts equipped durable gear that has lost durability (combat wear).
    # Repair remains deferred; this only surfaces the wear state in the HUD.
    class EquippedWear
      Summary = Struct.new(:worn, :broken, keyword_init: true)

      def self.summary_for(character)
        new(character:).summary
      end

      def initialize(character:)
        @character = character
      end

      def summary
        items = equipped_durable
        worn = items.count { |item| item.current_durability.to_i < item.max_durability.to_i }
        broken = items.count(&:broken?)
        Summary.new(worn:, broken:)
      end

      private

      attr_reader :character

      def equipped_durable
        inventory = character&.inventory
        return [] unless inventory

        inventory.inventory_items.includes(:item_template).equipped.select(&:durable?)
      end
    end
  end
end
