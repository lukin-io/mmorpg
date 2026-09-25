# frozen_string_literal: true

module Manage
  class PlayableRegionsController < ApplicationController
    def create
      authorize :manage, :access?
      region = Game::World::PlayableRegionBuilder.new.call
      population = Game::World::AshenPopulation.new.call
      status = Game::World::PlayableRegionStatus.record!(
        result: region,
        source: "manage",
        actor_id: current_user.id
      )
      ManagementAuditEvent.create!(
        actor: current_user,
        action: "update",
        record_type: "PlayableRegion",
        record_id: 0,
        record_label: "playable_region_100x100",
        change_set: status.slice(
          "cells_created", "cells_updated", "fortresses", "dungeon_npcs",
          "landmark_cells", "fortress_rows"
        ),
        metadata: {"source" => "manage_playable_region", "bots_placed" => population.placed,
                   "bots_updated" => population.updated}
      )
      redirect_to manage_root_path,
        notice: t(
          "manage.playable_region.done",
          cells_created: region.cells_created,
          cells_updated: region.cells_updated,
          fortresses: region.fortresses,
          dungeon_npcs: region.dungeon_npcs,
          bots_placed: population.placed,
          bots_updated: population.updated
        )
    rescue StandardError => error
      redirect_to manage_root_path, alert: error.message
    end
  end
end
