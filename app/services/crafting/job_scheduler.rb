# frozen_string_literal: true

module Crafting
  # Creates crafting jobs and computes completion timestamps with respect to station capacity.
  #
  # Usage:
  #   Crafting::JobScheduler.new(user: current_user, recipe: recipe, station: station).enqueue!
  #
  # Returns:
  #   CraftingJob record.
  class JobScheduler
    def initialize(user:, recipe:, station:, validator: Crafting::RecipeValidator.new(user:, recipe:))
      @user = user
      @recipe = recipe
      @station = station
      @validator = validator
    end

    def enqueue!
      validator.validate!
      CraftingJob.create!(
        user:,
        recipe:,
        crafting_station: station,
        status: :queued,
        started_at: Time.current,
        completes_at: Time.current + recipe.duration_seconds.seconds
      )
    end

    private

    attr_reader :user, :recipe, :station, :validator
  end
end

