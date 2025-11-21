# frozen_string_literal: true

module Game
  module Formulas
    class CritFormula < BaseFormula
      def call(attacker, defender)
        chance = attacker.stats.get(:crit_chance) - defender.stats.get(:luck)
        (rng.rand(100) < chance) ? 2.0 : 1.0
      end
    end
  end
end
