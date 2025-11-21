# frozen_string_literal: true

module Game
  module Formulas
    class DamageFormula < BaseFormula
      def call(attacker, defender)
        attack = attacker.stats.get(:attack)
        defense = defender.stats.get(:defense)

        base_damage = attack - (defense / 2)
        base_damage.positive? ? base_damage : 1
      end
    end
  end
end
