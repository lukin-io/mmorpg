# frozen_string_literal: true

class PlayersController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_device_identifier
  before_action :set_character

  def show
    @equipment = equipped_items_for(@character)
    @viewer_character = current_user&.character if user_signed_in?

    respond_to do |format|
      format.html
      format.json { render json: player_payload }
    end
  end

  private

  def set_character
    @character = Character
      .includes(:user, {inventory: {inventory_items: :item_template}}, {position: :zone})
      .find_by!("LOWER(characters.name) = ?", params[:name].to_s.downcase)
  end

  def equipped_items_for(character)
    return {} unless character.inventory

    character.inventory.inventory_items.equipped.includes(:item_template).index_by do |item|
      item.equipment_slot.to_s.presence || item.item_template&.slot.to_s
    end
  end

  def player_payload
    {
      public_player_path: player_path(name: @character.name),
      character: {
        id: @character.id,
        name: @character.name,
        level: @character.level,
        experience: @character.experience,
        experience_to_next_level: @character.experience_to_next_level,
        location: location_payload,
        equipment: equipment_payload,
        current_hp: @character.current_hp,
        max_hp: @character.max_hp,
        current_mp: @character.current_mp,
        max_mp: @character.max_mp
      }
    }
  end

  def location_payload
    position = @character.position
    return {label: "Unknown"} unless position

    if (match = active_arena_match_for(@character))
      sublocation = match.arena_room&.name || "Arena"
      return {
        label: "#{position.zone&.name} [in combat] #{sublocation}",
        zone: position.zone&.name,
        x: position.x,
        y: position.y,
        sublocation: sublocation,
        active_fight: {
          id: match.id,
          path: public_fight_log_path(match),
          status: match.status
        }
      }
    end

    label = [position.zone&.name, "[#{position.x}, #{position.y}]"].compact.join(" ")
    {
      label: label,
      zone: position.zone&.name,
      x: position.x,
      y: position.y
    }
  end

  def equipment_payload
    @equipment.to_h.transform_values do |item|
      template = item.item_template
      {
        id: item.id,
        name: template&.name,
        slot: item.equipment_slot.to_s.presence || template&.slot.to_s,
        rarity: template&.rarity,
        item_type: template&.item_type,
        quantity: item.quantity,
        current_durability: item.current_durability,
        max_durability: item.max_durability
      }
    end
  end

  def active_arena_match_for(character)
    character.arena_participations.includes(arena_match: :arena_room).order(created_at: :desc).detect do |participation|
      match = participation.arena_match
      next false unless match

      match.live? || match.pending? || match.matching? || (match.completed? && participation.metadata.to_h["finished_at"].blank?)
    end&.arena_match
  end
end
