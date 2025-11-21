# frozen_string_literal: true

module Crafting
  # Ensures a player meets skill/tool requirements before starting a crafting job.
  #
  # Usage:
  #   Crafting::RecipeValidator.new(user: current_user, recipe: recipe).validate!
  #
  # Raises:
  #   Pundit::NotAuthorizedError if requirements are missing.
  class RecipeValidator
    def initialize(user:, recipe:)
      @user = user
      @recipe = recipe
    end

    def validate!
      progress = user.profession_progresses.find_by!(profession: recipe.profession)
      required_level = recipe.requirements["skill_level"].to_i
      return true if progress.skill_level >= required_level

      raise Pundit::NotAuthorizedError, "Skill level too low for recipe"
    end

    private

    attr_reader :user, :recipe
  end
end

