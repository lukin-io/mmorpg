# frozen_string_literal: true

module Game
  module Combat
    class AttackService
      def initialize(turn_resolver: TurnResolver)
        @turn_resolver = turn_resolver
      end

      def call(attacker:, defender:, action:, rng_seed: 1)
        turn_resolver.new(
          attacker: attacker,
          defender: defender,
          action: action,
          rng: Random.new(rng_seed)
        ).call
      end

      private

      attr_reader :turn_resolver
    end
  end
end
