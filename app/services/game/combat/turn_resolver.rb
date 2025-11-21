# frozen_string_literal: true

module Game
  module Combat
    class TurnResolver
      Result = Struct.new(:log, :hp_changes, :effects, keyword_init: true)

      def initialize(attacker:, defender:, action:, rng: Random.new(1))
        @attacker = attacker
        @defender = defender
        @action = action
        @rng = rng
      end

      def call
        damage_formula = Game::Formulas::DamageFormula.new(rng: rng)
        crit_formula = Game::Formulas::CritFormula.new(rng: rng)

        damage = damage_formula.call(attacker, defender)
        crit_multiplier = crit_formula.call(attacker, defender)
        total_damage = (damage * crit_multiplier).to_i

        Result.new(
          log: ["#{attacker.name} used #{action} for #{total_damage} damage#{" (CRIT)" if crit_multiplier > 1}"],
          hp_changes: {defender: -total_damage},
          effects: []
        )
      end

      private

      attr_reader :attacker, :defender, :action, :rng
    end
  end
end
