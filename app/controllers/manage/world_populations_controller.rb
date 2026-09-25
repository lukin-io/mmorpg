# frozen_string_literal: true

module Manage
  class WorldPopulationsController < ApplicationController
    def create
      authorize :manage, :access?
      result = Game::World::AshenPopulation.new.call
      redirect_to manage_tile_npcs_path,
        notice: t("manage.world_population.done", placed: result.placed, updated: result.updated, skipped: result.skipped)
    rescue StandardError => error
      redirect_to manage_tile_npcs_path, alert: error.message
    end
  end
end
