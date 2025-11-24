# frozen_string_literal: true

module Game
  module Inventory
    # ExpansionService grants additional slot/weight capacity via housing storage or premium token purchases.
    #
    # Usage:
    #   Game::Inventory::ExpansionService.new(character:).expand!(source: :housing)
    #   Game::Inventory::ExpansionService.new(character:).expand!(source: :premium, premium_cost: 50)
    class ExpansionService
      DEFAULT_SLOT_BONUS = 5
      DEFAULT_WEIGHT_BONUS = 50
      DEFAULT_PREMIUM_COST = 25

      def initialize(character:, ledger: Payments::PremiumTokenLedger)
        @character = character
        @ledger = ledger
      end

      def expand!(source:, premium_cost: DEFAULT_PREMIUM_COST, slot_bonus: DEFAULT_SLOT_BONUS, weight_bonus: DEFAULT_WEIGHT_BONUS)
        case source.to_sym
        when :housing
          apply_housing_expansion!
        when :premium
          apply_premium_expansion!(premium_cost:)
        when :artifact
          apply_expansion(slot_bonus:, weight_bonus:)
        else
          raise ArgumentError, "Unknown expansion source #{source}"
        end
      end

      private

      attr_reader :character, :ledger

      def inventory
        character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
      end

      def apply_housing_expansion!
        plot = character.user&.housing_plots&.order(storage_slots: :desc)&.first
        raise Pundit::NotAuthorizedError, "Housing required" unless plot

        slot_bonus = [plot.storage_slots / 4, DEFAULT_SLOT_BONUS].max
        weight_bonus = slot_bonus * 10
        apply_expansion(slot_bonus:, weight_bonus:)
      end

      def apply_premium_expansion!(premium_cost:)
        raise ArgumentError, "premium_cost must be positive" unless premium_cost.to_i.positive?

        ledger.debit(
          user: character.user,
          amount: premium_cost,
          reason: "inventory_expansion",
          actor: character.user,
          metadata: {character_id: character.id}
        )

        apply_expansion(slot_bonus: DEFAULT_SLOT_BONUS, weight_bonus: DEFAULT_WEIGHT_BONUS)
      rescue Payments::PremiumTokenLedger::InsufficientBalanceError => e
        raise Pundit::NotAuthorizedError, e.message
      end

      def apply_expansion(slot_bonus:, weight_bonus:)
        inventory.increment!(:slot_capacity, slot_bonus)
        inventory.increment!(:weight_capacity, weight_bonus)
        inventory
      end
    end
  end
end
