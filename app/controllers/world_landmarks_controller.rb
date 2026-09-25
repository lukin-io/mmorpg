# frozen_string_literal: true

class WorldLandmarksController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  def claim_fortress
    result = Game::World::FortressClaim.new(
      character: current_character,
      fortress_key: params[:fortress_key],
      side: params[:side].presence || "attack"
    ).call
    flash_key = result.success ? :notice : :alert
    redirect_to world_path, flash_key => result.message, status: :see_other
  end

  def enter_dungeon
    character = current_character
    pos = character.position
    unless pos
      redirect_to world_path, alert: t("game.world.character_unavailable"), status: :see_other
      return
    end

    tile = MapTileTemplate.find_by(zone: pos.zone.name, x: pos.x, y: pos.y)
    landmark = tile&.metadata.to_h["landmark"].to_h
    pack = Game::Instances::DungeonPacks.all.find { |row| row["map_x"].to_i == pos.x && row["map_y"].to_i == pos.y }

    if pack
      result = Game::Instances::PackLaunch.new(character:, pack_key: pack["key"]).call
      if result.success?
        redirect_to arena_match_path(result.match), notice: result.message, status: :see_other
      else
        redirect_to world_path, alert: result.message, status: :see_other
      end
      return
    end

    unless landmark["kind"] == "dungeon"
      redirect_to world_path, alert: t("game.world.dungeon_missing"), status: :see_other
      return
    end

    # Prefer pack keyed by landmark key when present.
    pack = Game::Instances::DungeonPacks.find(landmark["key"]) ||
      Game::Instances::DungeonPacks.all.find { |row| row["name"] == landmark["name"] }
    if pack
      result = Game::Instances::PackLaunch.new(character:, pack_key: pack["key"]).call
      if result.success?
        redirect_to arena_match_path(result.match), notice: result.message, status: :see_other
      else
        redirect_to world_path, alert: result.message, status: :see_other
      end
      return
    end

    instance_id = landmark["instance_id"].presence || params[:instance_id].presence
    if instance_id.blank?
      redirect_to instances_path(tab: "dungeon"),
        notice: t("game.world.dungeon_open_list", name: landmark["name"]),
        status: :see_other
      return
    end

    result = Game::Instances::Launch.new(
      character:,
      instance_kind: "dungeon",
      instance_id:
    ).call
    if result.success?
      redirect_to arena_match_path(result.match), notice: result.message, status: :see_other
    else
      redirect_to instances_path(tab: "dungeon"), alert: result.message, status: :see_other
    end
  end
end
