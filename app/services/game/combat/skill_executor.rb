# frozen_string_literal: true

module Game
  module Combat
    class SkillExecutor
      def self.call(*args, **kwargs)
        new(*args, **kwargs).call
      end

      def initialize(ability:, attacker:, defender:, rng_seed: 1, battle: nil)
        raise ArgumentError, "Ability required" unless ability

        @ability = ability
        @attacker = attacker
        @defender = defender
        @rng = Random.new(rng_seed)
        @battle = battle
      end

      def call
        enforce_resource_cost!
        Game::Combat::TurnResolver.new(
          attacker:,
          defender:,
          action: ability.name,
          rng:,
          battle:,
          ability:
        ).call
      end

      private

      attr_reader :ability, :attacker, :defender, :rng, :battle

      def enforce_resource_cost!
        ability.resource_cost.each do |pool, amount|
          current = attacker.resource_pools.fetch(pool, 0)
          raise Pundit::NotAuthorizedError, "Not enough #{pool}" if current < amount

          attacker.resource_pools_will_change!
          attacker.resource_pools[pool] = current - amount
        end
        attacker.save! if attacker.changed?
      end
    end
  end
end
