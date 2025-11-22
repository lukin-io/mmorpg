# frozen_string_literal: true

module Game
  module Inventory
    # EnhancementService applies enchant/enhance attempts with crafting skill modifiers.
    #
    # Usage:
    #   Game::Inventory::EnhancementService.new(item:, crafter_progress:).attempt!
    #
    # Returns:
    #   :success or :failure outcome symbol.
    class EnhancementService
      def initialize(item:, crafter_progress:, rng: Random.new(1))
        @item = item
        @crafter_progress = crafter_progress
        @rng = rng
      end

      def attempt!
        ensure_crafter_allowed!

        if rng.rand(100) < success_chance
          item.increment!(:enhancement_level)
          item.update!(last_enhanced_at: Time.current)
          :success
        else
          apply_failure_penalty
          :failure
        end
      end

      private

      attr_reader :item, :crafter_progress, :rng

      def ensure_crafter_allowed!
        required_skill = item.item_template.enhancement_rules["required_skill_level"].to_i
        return if crafter_progress.skill_level >= required_skill

        raise Pundit::NotAuthorizedError, "Crafting skill too low for enhancement"
      end

      def success_chance
        base = item.item_template.enhancement_rules["base_success_chance"].to_i
        mastery_bonus = crafter_progress.skill_level * 0.5
        [base + mastery_bonus, 95].min
      end

      def apply_failure_penalty
        penalty = item.item_template.enhancement_rules["failure_penalty"] || "downgrade"
        case penalty
        when "downgrade"
          item.decrement!(:enhancement_level) if item.enhancement_level.positive?
        when "destroy"
          item.destroy
        end
      end
    end
  end
end
