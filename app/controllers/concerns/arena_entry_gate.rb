# frozen_string_literal: true

module ArenaEntryGate
  extend ActiveSupport::Concern

  private

  def require_city_arena_entry!
    return if current_character_has_active_arena_match?
    return if session[:arena_city_character_id].to_i == current_character&.id.to_i

    redirect_to world_path, alert: "Enter the arena through the city building."
  end

  def mark_city_arena_entry!(hotspot)
    return unless hotspot&.key == "arena"

    session[:arena_city_character_id] = current_character.id
    session[:arena_city_zone_id] = current_character.position&.zone_id
  end

  def current_character_has_active_arena_match?
    return false unless current_character

    current_character.arena_participations
      .joins(:arena_match)
      .where(arena_matches: {status: [:pending, :matching, :live]})
      .exists?
  end
end
