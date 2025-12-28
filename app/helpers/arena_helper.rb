# frozen_string_literal: true

module ArenaHelper
  include AlignmentHelper

  # Room type icons and labels
  ROOM_TYPE_CONFIG = {
    training: {emoji: "🏋️", label: "Training Hall", description: "Levels 0-5, reduced penalties"},
    trial: {emoji: "⚔️", label: "Trial Hall", description: "Levels 5-10, beginner competitive"},
    challenge: {emoji: "🗡️", label: "Challenge Arena", description: "Levels 5-33, open range duels"},
    initiation: {emoji: "🎖️", label: "Initiation Ring", description: "Levels 9-33, mid-level"},
    patron: {emoji: "👑", label: "Patron's Arena", description: "Levels 16-33, high-level"},
    law: {emoji: "⚖️", label: "Hall of Law", description: "Lawful faction only"},
    light: {emoji: "☀️", label: "Sanctum of Light", description: "Light alignment only"},
    balance: {emoji: "☯️", label: "Twilight Arena", description: "Neutral alignment only"},
    chaos: {emoji: "🔥", label: "Chaos Pit", description: "Chaotic faction only"},
    dark: {emoji: "🌑", label: "Shadow Arena", description: "Dark alignment only"}
  }.freeze

  # Fight type configuration with icons
  FIGHT_TYPE_CONFIG = {
    duel: {emoji: "⚔️", label: "1v1 Duel"},
    team_battle: {emoji: "👥", label: "Team Battle"},
    sacrifice: {emoji: "💀", label: "Free-for-All"},
    tactical: {emoji: "🎯", label: "Tactical Grid"}
  }.freeze

  # Fight kind configuration with icons
  FIGHT_KIND_CONFIG = {
    no_weapons: {emoji: "🥊", label: "Bare Hands"},
    no_artifacts: {emoji: "🚫", label: "No Magic Items"},
    limited_artifacts: {emoji: "⚠️", label: "Limited Equipment"},
    free: {emoji: "✅", label: "All Equipment"},
    clan_vs_clan: {emoji: "🏰", label: "Clan vs Clan"},
    faction_vs_faction: {emoji: "🎌", label: "Faction vs Faction"}
  }.freeze

  # Match status icons
  MATCH_STATUS_CONFIG = {
    pending: {emoji: "⏳", label: "Pending", css: "pending"},
    matching: {emoji: "🔍", label: "Finding Opponent", css: "matching"},
    countdown: {emoji: "⏰", label: "Starting Soon", css: "countdown"},
    live: {emoji: "🔴", label: "LIVE", css: "live"},
    completed: {emoji: "✅", label: "Completed", css: "completed"},
    cancelled: {emoji: "❌", label: "Cancelled", css: "cancelled"}
  }.freeze

  # Get icon for room type
  def room_type_icon(room_type)
    ROOM_TYPE_CONFIG.dig(room_type.to_sym, :emoji) || "🏟️"
  end

  # Get room type badge with icon and label
  def room_type_badge(room_type)
    config = ROOM_TYPE_CONFIG[room_type.to_sym] || {emoji: "🏟️", label: room_type.to_s.humanize}
    content_tag(:span, "#{config[:emoji]} #{config[:label]}", class: "room-type-badge room-type-#{room_type}", title: config[:description])
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

  # Format fight type for display with icon
  def fight_type_label(fight_type)
    config = FIGHT_TYPE_CONFIG[fight_type.to_sym]
    config ? config[:label] : fight_type.to_s.humanize
  end

  def fight_type_with_icon(fight_type)
    config = FIGHT_TYPE_CONFIG[fight_type.to_sym] || {emoji: "⚔️", label: fight_type.to_s.humanize}
    "#{config[:emoji]} #{config[:label]}"
  end

  # Format fight kind for display with icon
  def fight_kind_label(fight_kind)
    config = FIGHT_KIND_CONFIG[fight_kind.to_sym]
    config ? config[:label] : fight_kind.to_s.humanize
  end

  def fight_kind_with_icon(fight_kind)
    config = FIGHT_KIND_CONFIG[fight_kind.to_sym] || {emoji: "⚔️", label: fight_kind.to_s.humanize}
    "#{config[:emoji]} #{config[:label]}"
  end

  # Match status badge
  def arena_match_status_badge(status)
    config = MATCH_STATUS_CONFIG[status.to_sym] || {emoji: "❓", label: status.to_s.humanize, css: "unknown"}
    content_tag(:span, "#{config[:emoji]} #{config[:label]}", class: "match-status match-status--#{config[:css]}")
  end

  # Application status tag
  def arena_room_status_tag(room)
    if room.has_capacity?
      content_tag(:span, "🟢 Open", class: "room-status room-status--open")
    else
      content_tag(:span, "🔴 Full", class: "room-status room-status--full")
    end
  end

  def arena_match_status_tag(match)
    arena_match_status_badge(match.status)
  end

  # Full application display with all settings
  def application_settings_display(application)
    parts = []
    parts << fight_type_icon_only(application.fight_type)
    parts << fight_kind_icon_only(application.fight_kind)
    parts << timeout_icon_only(application.timeout_seconds)
    parts << trauma_icon_only(application.trauma_percent)

    content_tag(:span, safe_join(parts, " "), class: "application-settings")
  end

  # Opponent display with alignment
  def opponent_display(character, current_character)
    return "Waiting for opponent..." unless character

    alignment_class = (character.faction_alignment == current_character&.faction_alignment) ? "ally" : "enemy"

    content_tag(:div, class: "opponent-display opponent-display--#{alignment_class}") do
      safe_join([
        alignment_icons(character),
        content_tag(:strong, character.name),
        content_tag(:span, " [#{character.level}]", class: "opponent-level")
      ])
    end
  end

  # Format level range for display
  def level_range_display(room)
    min = room.respond_to?(:level_min) ? room.level_min : room.min_level
    max = room.respond_to?(:level_max) ? room.level_max : room.max_level

    if min == max
      "Lvl #{min}"
    else
      "Lvl #{min}-#{max}"
    end
  end

  # ===========================================================================
  # Participant Data Helpers
  # ===========================================================================

  # Struct to hold participant display data
  ParticipantData = Struct.new(
    :name, :level, :id, :is_npc,
    :current_hp, :max_hp, :current_mp, :max_mp,
    :hp_percent, :mp_percent,
    keyword_init: true
  )

  # Extract participant display data from arena participation
  # @param participation [ArenaParticipation] the participation record
  # @return [ParticipantData] structured participant data
  def participant_data(participation)
    character = participation.character
    npc_template = participation.npc_template
    is_npc = npc_template.present?

    if is_npc
      current_hp = participation.metadata&.dig("current_hp") || npc_template.health
      max_hp = participation.metadata&.dig("max_hp") || npc_template.health
      current_mp = 0
      max_mp = 0
      name = npc_template.name
      level = npc_template.level
      participant_id = "npc-#{npc_template.id}"
    else
      current_hp = character.current_hp
      max_hp = character.max_hp
      current_mp = character.current_mp
      max_mp = character.max_mp
      name = character.name
      level = character.level
      participant_id = character.id
    end

    hp_percent = max_hp.zero? ? 0 : ((current_hp.to_f / max_hp) * 100).round(1)
    mp_percent = max_mp.zero? ? 0 : ((current_mp.to_f / max_mp) * 100).round(1)

    ParticipantData.new(
      name: name,
      level: level,
      id: participant_id,
      is_npc: is_npc,
      current_hp: current_hp,
      max_hp: max_hp,
      current_mp: current_mp,
      max_mp: max_mp,
      hp_percent: hp_percent,
      mp_percent: mp_percent
    )
  end

  # Check if participant is dead
  # @param participation [ArenaParticipation] the participation record
  # @return [Boolean]
  def participant_dead?(participation)
    data = participant_data(participation)
    data.current_hp <= 0
  end
end
