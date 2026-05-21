# frozen_string_literal: true

module Players
  module Progression
    # LevelUpService awards XP, handles level ups, and grants stat/skill points.
    #
    # Purpose:
    #   Processes experience gains, triggers level ups, and awards:
    #   - Stat points (5 per level)
    #   - Combat skill points (1 per level)
    #   - Peace skill points (1 per level, starting at level 5)
    #
    # Inputs:
    #   - character: Character record to process
    #   - amount: Integer XP to award
    #
    # Returns:
    #   Character with updated level and point pools
    #
    # Usage:
    #   service = Players::Progression::LevelUpService.new(character: warrior)
    #   service.apply_experience!(250)
    #   # Character gains XP, possibly levels up, receives stat/skill points
    #
    class LevelUpService
      STAT_POINTS_PER_LEVEL = 5
      SKILL_POINTS_PER_LEVEL = 1          # Mirrors total unspent numeric skill points
      COMBAT_SKILL_POINTS_PER_LEVEL = 1   # Combat/magic/resistance skills
      PEACE_SKILL_POINTS_START_LEVEL = 5  # Peace skills unlock at level 5
      PEACE_SKILL_POINTS_PER_LEVEL = 1    # Peace skills
      PERK_POINTS_LEVEL_INTERVAL = 5      # Earn 1 perk point every 5 levels

      Result = Struct.new(:character, :levels_gained, :stat_points_gained,
        :combat_skill_points_gained, :peace_skill_points_gained, :perk_points_gained, keyword_init: true)

      def initialize(character:)
        @character = character
        @levels_gained = 0
        @stat_points_gained = 0
        @combat_skill_points_gained = 0
        @peace_skill_points_gained = 0
        @perk_points_gained = 0
      end

      # Apply experience and process any resulting level ups
      #
      # @param amount [Integer] XP to award
      # @return [Result] result with character and points gained
      def apply_experience!(amount)
        Character.transaction do
          character.increment!(:experience, amount)
          process_level_ups
        end

        Result.new(
          character: character,
          levels_gained: @levels_gained,
          stat_points_gained: @stat_points_gained,
          combat_skill_points_gained: @combat_skill_points_gained,
          peace_skill_points_gained: @peace_skill_points_gained,
          perk_points_gained: @perk_points_gained
        )
      end

      # Force a level up (for testing or admin purposes)
      #
      # @param levels [Integer] number of levels to grant (default 1)
      # @return [Result] result with character and points gained
      def force_level_up!(levels: 1)
        Character.transaction do
          levels.times do
            grant_level_up_rewards
          end
          character.update!(last_level_up_at: Time.current)
        end

        Result.new(
          character: character,
          levels_gained: @levels_gained,
          stat_points_gained: @stat_points_gained,
          combat_skill_points_gained: @combat_skill_points_gained,
          peace_skill_points_gained: @peace_skill_points_gained,
          perk_points_gained: @perk_points_gained
        )
      end

      private

      attr_reader :character

      def process_level_ups
        while character.experience >= xp_required_for(character.level + 1)
          grant_level_up_rewards
        end

        character.update!(last_level_up_at: Time.current) if @levels_gained.positive?
      end

      def grant_level_up_rewards
        new_level = character.level + 1

        # Increment level
        character.increment!(:level)
        @levels_gained += 1

        # Grant stat points
        character.increment!(:stat_points_available, STAT_POINTS_PER_LEVEL)
        @stat_points_gained += STAT_POINTS_PER_LEVEL

        # Maintain the aggregate skill-point counter alongside split pools.
        character.increment!(:skill_points_available, SKILL_POINTS_PER_LEVEL)

        # Grant combat skill points (every level)
        character.increment!(:combat_skill_points, COMBAT_SKILL_POINTS_PER_LEVEL)
        @combat_skill_points_gained += COMBAT_SKILL_POINTS_PER_LEVEL

        # Grant peace skill points (from level 5 onwards)
        if new_level >= PEACE_SKILL_POINTS_START_LEVEL
          character.increment!(:peace_skill_points, PEACE_SKILL_POINTS_PER_LEVEL)
          @peace_skill_points_gained += PEACE_SKILL_POINTS_PER_LEVEL
        end

        # Grant perk point (every 5 levels)
        if (new_level % PERK_POINTS_LEVEL_INTERVAL).zero?
          character.increment!(:perk_points_available, 1)
          @perk_points_gained += 1
        end

        # Restore HP/MP to full on level up
        if character.respond_to?(:max_hp) && character.respond_to?(:current_hp)
          character.update!(current_hp: character.max_hp)
        end

        if character.respond_to?(:max_mp) && character.respond_to?(:current_mp)
          character.update!(current_mp: character.max_mp)
        end
      end

      # XP required to reach a given level.
      # Level 2 starts at 100 total XP, matching the observed starter profile.
      def xp_required_for(level)
        Character.xp_required_for_level(level)
      end
    end
  end
end
