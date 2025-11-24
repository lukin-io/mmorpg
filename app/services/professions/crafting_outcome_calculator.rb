# frozen_string_literal: true

module Professions
  # Calculates success chance and quality tiers for a crafting attempt.
  #
  # Usage:
  #   Professions::CraftingOutcomeCalculator.new(progress:, recipe:, station:).preview
  #
  # Returns:
  #   Struct with :success_chance, :quality_tier, :quality_score
  class CraftingOutcomeCalculator
    Result = Struct.new(:success_chance, :quality_tier, :quality_score, :success, keyword_init: true)

    QUALITY_BANDS = {
      legendary: 95,
      epic: 80,
      rare: 65,
      uncommon: 45,
      common: 0
    }.freeze

    def initialize(progress:, recipe:, station:, tool: nil, rng: Random.new(1))
      @progress = progress
      @recipe = recipe
      @station = station
      @tool = tool || progress.best_tool
      @rng = rng
    end

    def preview
      Result.new(
        success_chance: success_chance,
        quality_tier: quality_tier,
        quality_score: quality_score,
        success: nil
      )
    end

    def resolve!
      success_roll = rng.rand(100)
      success = success_roll < success_chance
      Result.new(
        success_chance: success_chance,
        quality_tier: quality_tier,
        quality_score: quality_score,
        success: success
      )
    end

    def success_chance
      @success_chance ||= begin
        base = 70
        base += (progress.skill_level - required_skill_level) * 3
        base += tool_quality / 2
        base += progress.buff_bonus
        base += station_bonus
        base -= recipe.success_penalty
        base -= station.success_penalty
        base -= 10 if recipe.risky?
        base.clamp(15, 98)
      end
    end

    def quality_tier
      @quality_tier ||= begin
        score = quality_score
        QUALITY_BANDS.find { |_tier, threshold| score >= threshold }.first.to_s
      end
    end

    def quality_score
      @quality_score ||= begin
        score = progress.skill_level * 2
        score += tool_quality
        score += progress.buff_bonus
        score += station_bonus
        score -= recipe.tier * 5
        score -= recipe.success_penalty
        score -= station.success_penalty
        score.clamp(0, 120)
      end
    end

    private

    attr_reader :progress, :recipe, :station, :tool, :rng

    def required_skill_level
      recipe.requirements["skill_level"].to_i
    end

    def tool_quality
      tool&.quality_rating.to_i
    end

    def station_bonus
      case station.station_archetype
      when "city" then 5
      when "guild_hall" then 10
      when "field_kit" then -15
      else
        0
      end
    end
  end
end
