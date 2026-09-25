# frozen_string_literal: true

module Game
  module World
    # Ashen outdoor bait for forced same-cell fights.
    # Passive ambushes do not consume bait; InterruptAction / lure does.
    class Bait
      ITEM_KEY = "ashen_bait"
      STARTER_GRANT = 5

      class MissingBaitError < StandardError; end

      def self.item_template
        ItemTemplate.find_by(key: ITEM_KEY)
      end

      def initialize(character:)
        @character = character
      end

      def quantity
        template = self.class.item_template
        return 0 unless template && character.inventory

        character.inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
      end

      def available?
        quantity.positive?
      end

      # Consumes one bait under the character inventory lock. Raises MissingBaitError
      # when none remains.
      def consume!(reason: "world.bait")
        template = self.class.item_template
        raise MissingBaitError, I18n.t("game.world.bait_missing") unless template

        inventory = character.inventory
        raise MissingBaitError, I18n.t("game.world.bait_missing") unless inventory

        inventory.with_lock do
          rows = inventory.inventory_items.where(item_template: template, equipped: false).order(:id).lock.to_a
          raise MissingBaitError, I18n.t("game.world.bait_missing") if rows.sum(&:quantity) <= 0

          row = rows.find { |item| item.quantity.to_i.positive? }
          raise MissingBaitError, I18n.t("game.world.bait_missing") unless row

          if row.quantity.to_i <= 1
            row.destroy!
          else
            row.update!(quantity: row.quantity - 1)
          end
          inventory.update!(current_weight: inventory.inventory_items.sum("weight * quantity"))
        end

        true
      end

      private

      attr_reader :character
    end
  end
end
