# frozen_string_literal: true

module Crafting
  # Ensures a character meets profession, material, and station requirements before queueing crafts.
  #
  # Usage:
  #   Crafting::RecipeValidator.new(character: current_character, recipe:, station:).validate!
  #
  # Raises:
  #   Pundit::NotAuthorizedError when requirements are not met.
  class RecipeValidator
    def initialize(character:, recipe:, station:)
      @character = character
      @recipe = recipe
      @station = station
    end

    def validate!
      ensure_progress!
      ensure_skill_level!
      ensure_station_match!
      ensure_guild_unlock!
      ensure_materials!
      ensure_tool_available!
      true
    end

    def profession_progress
      progress
    end

    private

    attr_reader :character, :recipe, :station

    def ensure_progress!
      raise Pundit::NotAuthorizedError, "Profession not learned" unless progress
    end

    def ensure_skill_level!
      required_level = recipe.requirements["skill_level"].to_i
      return if progress.skill_level >= required_level

      raise Pundit::NotAuthorizedError, "Skill level too low for recipe"
    end

    def ensure_station_match!
      return if recipe.required_station_archetype == station.station_archetype
      return if station.portable? && recipe.tier <= 2

      raise Pundit::NotAuthorizedError, "Crafting station not compatible"
    end

    def ensure_guild_unlock!
      return unless recipe.guild_locked?
      return if character.guild.present?

      raise Pundit::NotAuthorizedError, "Guild membership required"
    end

    def ensure_materials!
      mats = recipe.materials
      return if mats.blank?
      return if inventory&.materials_available?(mats)

      raise Pundit::NotAuthorizedError, "Missing required materials"
    end

    def ensure_tool_available!
      return if progress.best_tool

      raise Pundit::NotAuthorizedError, "Crafting tool required"
    end

    def progress
      @progress ||= character.profession_progresses.find_by(profession: recipe.profession)
    end

    def inventory
      character.inventory
    end
  end
end
