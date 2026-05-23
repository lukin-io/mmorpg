# frozen_string_literal: true

module Game
  module Systems
    class StatBlock
      attr_reader :base, :mods

      def initialize(base:, mods: {})
        @base = base
        @mods = mods
      end

      def get(stat)
        key = canonical_stat(stat)
        (base[key] || 0) + (mods[key] || 0)
      end

      def apply_mod!(stat, value)
        key = canonical_stat(stat)
        mods[key] ||= 0
        mods[key] += value
      end

      private

      def canonical_stat(stat)
        stat.to_sym
      end
    end
  end
end
