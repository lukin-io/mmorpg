# frozen_string_literal: true

module Players
  module Progression
    # Atomically awards combat experience and applies the source-backed
    # Neverlands level grants. The table is finite by design: incomplete wiki
    # rows are not extrapolated into invented progression.
    class LevelUpService
      class ProgressionError < StandardError; end

      Result = Data.define(
        :character,
        :levels_gained,
        :stat_points_gained,
        :combat_skill_points_gained,
        :peace_skill_points_gained,
        :perk_points_gained,
        :nv_gained
      )

      def initialize(character:)
        @character = character
      end

      def apply_experience!(amount)
        gained_experience = Integer(amount, exception: false)
        raise ProgressionError, "Experience must be a non-negative integer" unless gained_experience&.>= 0

        reset_totals
        ApplicationRecord.transaction do
          character.with_lock do
            character.reload
            character.experience += gained_experience
            process_level_ups
            character.last_level_up_at = Time.current if @levels_gained.positive?
            character.save!
            award_nv!
          end
        end

        Result.new(
          character:,
          levels_gained: @levels_gained,
          stat_points_gained: @stat_points_gained,
          combat_skill_points_gained: @combat_skill_points_gained,
          peace_skill_points_gained: @peace_skill_points_gained,
          perk_points_gained: @perk_points_gained,
          nv_gained: @nv_gained
        )
      end

      private

      attr_reader :character

      def reset_totals
        @levels_gained = 0
        @stat_points_gained = 0
        @combat_skill_points_gained = 0
        @peace_skill_points_gained = 0
        @perk_points_gained = 0
        @nv_gained = 0
      end

      def process_level_ups
        loop do
          next_level = character.level.to_i + 1
          threshold = Character.xp_required_for_level(next_level)
          break unless threshold && character.experience.to_i >= threshold

          rewards = Game::Progression::Catalog.rewards_for_level(next_level)
          break unless rewards

          apply_level_rewards(next_level, rewards)
        end
      end

      def apply_level_rewards(next_level, rewards)
        character.level = next_level
        add_reward(:stat_points_available, rewards, "stat_points", :@stat_points_gained)
        add_reward(:combat_skill_points, rewards, "combat_skill_points", :@combat_skill_points_gained)
        add_reward(:peace_skill_points, rewards, "peace_skill_points", :@peace_skill_points_gained)
        add_reward(:perk_points, rewards, "perk_points", :@perk_points_gained)
        @nv_gained += rewards.fetch("nv")
        @levels_gained += 1
      end

      def add_reward(attribute, rewards, reward_key, total_variable)
        amount = rewards.fetch(reward_key)
        character.public_send("#{attribute}=", character.public_send(attribute).to_i + amount)
        instance_variable_set(total_variable, instance_variable_get(total_variable) + amount)
      end

      def award_nv!
        return unless @nv_gained.positive?

        character.user.currency_wallet.adjust!(
          amount: @nv_gained,
          reason: "progression.level_up",
          metadata: {
            "character_id" => character.id,
            "level" => character.level,
            "levels_gained" => @levels_gained
          }
        )
      end
    end
  end
end
