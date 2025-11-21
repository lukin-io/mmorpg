# frozen_string_literal: true

module Game
  module Combat
    class SkillExecutor
      def self.call(*args, **kwargs)
        new(*args, **kwargs).call
      end

      def initialize(skill:, attacker:, defender:, rng_seed: 1)
        @skill = skill
        @attacker = attacker
        @defender = defender
        @rng = Random.new(rng_seed)
      end

      def call
        Game::Combat::TurnResolver.new(
          attacker: attacker,
          defender: defender,
          action: skill.name,
          rng: rng
        ).call
      end

      private

      attr_reader :skill, :attacker, :defender, :rng
    end
  end
end
