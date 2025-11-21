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
        (base[stat] || 0) + (mods[stat] || 0)
      end

      def apply_mod!(stat, value)
        mods[stat] ||= 0
        mods[stat] += value
      end
    end
  end
end
