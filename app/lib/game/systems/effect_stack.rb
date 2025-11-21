# frozen_string_literal: true

module Game
  module Systems
    class EffectStack
      attr_reader :effects

      def initialize
        @effects = []
      end

      def add(effect)
        effects << effect
      end

      def apply_to(stat_block)
        effects.each do |effect|
          effect.stat_changes.each do |stat, value|
            stat_block.apply_mod!(stat, value)
          end
        end
      end

      def tick!
        effects.each(&:tick!)
        effects.reject!(&:expired?)
      end
    end
  end
end
