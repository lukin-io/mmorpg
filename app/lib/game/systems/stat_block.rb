# frozen_string_literal: true

module Game
  module Systems
    class StatBlock
      STAT_ALIASES = {
        agility: :dexterity,
        dex: :dexterity,
        knowledge: :intelligence,
        intellect: :intelligence,
        health: :vitality,
        constitution: :vitality,
        stamina: :vitality
      }.freeze

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
        key = stat.to_sym
        STAT_ALIASES.fetch(key, key)
      end
    end
  end
end
