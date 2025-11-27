# frozen_string_literal: true

module ArenaHelper
  # Get icon for room type
  def room_type_icon(room_type)
    case room_type.to_sym
    when :training then "🏋️"
    when :trial then "⚔️"
    when :challenge then "🗡️"
    when :initiation then "🎖️"
    when :patron then "👑"
    when :law then "⚖️"
    when :light then "☀️"
    when :balance then "☯️"
    when :chaos then "🔥"
    when :dark then "🌑"
    else "🏟️"
    end
  end

  # Check if current user is participating in the match
  def current_user_participating?
    return false unless @arena_match && current_user

    @arena_match.arena_participations.exists?(user: current_user)
  end

  # Check if current user won the match
  def current_user_won?
    return false unless @arena_match&.completed? && current_user

    participation = @arena_match.arena_participations.find_by(user: current_user)
    return false unless participation

    participation.team == @arena_match.winning_team
  end

  # Format fight type for display
  def fight_type_label(fight_type)
    {
      duel: "Duel (1v1)",
      group: "Group Battle",
      sacrifice: "Free-for-All",
      tactical: "Tactical"
    }[fight_type.to_sym] || fight_type.to_s.humanize
  end

  # Format fight kind for display
  def fight_kind_label(fight_kind)
    {
      no_weapons: "Bare Hands",
      no_artifacts: "No Magic Items",
      limited_artifacts: "Limited Equipment",
      free: "All Equipment",
      clan_vs_clan: "Clan vs Clan",
      faction_vs_faction: "Faction vs Faction"
    }[fight_kind.to_sym] || fight_kind.to_s.humanize
  end
end
