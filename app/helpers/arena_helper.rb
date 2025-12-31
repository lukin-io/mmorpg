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
    :strength, :dexterity, :luck, :knowledge, :wisdom,
    keyword_init: true
  )

  # ===========================================================================
  # Match Display Helpers
  # ===========================================================================

  # Get winner name for display
  # @param match [ArenaMatch] the arena match
  # @return [String] winner's name
  def winner_name(match)
    return "Draw" unless match.winning_team

    winner_participation = match.arena_participations.find_by(team: match.winning_team)
    return "Unknown" unless winner_participation

    if winner_participation.npc?
      winner_participation.npc_template&.name || "NPC"
    else
      winner_participation.character&.name || "Player"
    end
  end

  # Format duration in human-readable format
  # @param seconds [Integer] duration in seconds
  # @return [String] formatted duration
  def format_duration(seconds)
    return "0s" unless seconds && seconds.positive?

    if seconds < 60
      "#{seconds}s"
    elsif seconds < 3600
      minutes = seconds / 60
      secs = seconds % 60
      secs.positive? ? "#{minutes}m #{secs}s" : "#{minutes}m"
    else
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      minutes.positive? ? "#{hours}h #{minutes}m" : "#{hours}h"
    end
  end

  # Get HP bar color class based on percentage
  # @param hp_percent [Numeric] HP percentage (0-100)
  # @return [String] CSS class suffix
  def hp_color_class(hp_percent)
    case hp_percent
    when 0..25 then "critical"
    when 26..50 then "low"
    when 51..75 then "medium"
    else "high"
    end
  end

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

    # Get stats (for opponent display)
    stats = if is_npc
      npc_combat_stats(npc_template)
    else
      character_combat_stats(character)
    end

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
      mp_percent: mp_percent,
      strength: stats[:strength] || 0,
      dexterity: stats[:dexterity] || 0,
      luck: stats[:luck] || 0,
      knowledge: stats[:knowledge] || 0,
      wisdom: stats[:wisdom] || 0
    )
  end

  # Check if participant is dead
  # @param participation [ArenaParticipation] the participation record
  # @return [Boolean]
  def participant_dead?(participation)
    data = participant_data(participation)
    data.current_hp <= 0
  end

  # ===========================================================================
  # Avatar Helpers
  # ===========================================================================

  # Avatar sizes in pixels
  AVATAR_SIZES = {
    small: 32,
    medium: 48,
    large: 64
  }.freeze

  # Generate avatar tag for arena participant
  # @param participation [ArenaParticipation] the participation record
  # @param size [Symbol] :small, :medium, or :large
  # @return [ActiveSupport::SafeBuffer] HTML span element with avatar
  def participation_avatar_tag(participation, size: :medium)
    size_px = AVATAR_SIZES[size] || AVATAR_SIZES[:medium]

    if participation.npc?
      npc = participation.npc_template
      avatar_emoji = npc&.avatar_emoji || "🤖"
      content_tag(:span, avatar_emoji, class: "avatar avatar--npc avatar--#{size}",
        style: "font-size: #{size_px}px; line-height: #{size_px}px;",
        title: npc&.name || "NPC")
    else
      character = participation.character
      avatar_class = character&.avatar || "warrior"
      # Use character class icon or default
      avatar_emoji = character_class_emoji(character)
      content_tag(:span, avatar_emoji, class: "avatar avatar--player avatar--#{size} avatar--#{avatar_class}",
        style: "font-size: #{size_px}px; line-height: #{size_px}px;",
        title: character&.name || "Player")
    end
  end

  # Get emoji for character class
  # @param character [Character] the character
  # @return [String] emoji representing the class
  def character_class_emoji(character)
    return "⚔️" unless character&.character_class

    case character.character_class.name.to_s.downcase
    when "warrior", "knight", "paladin" then "⚔️"
    when "mage", "wizard", "sorcerer" then "🔮"
    when "rogue", "thief", "assassin" then "🗡️"
    when "ranger", "archer", "hunter" then "🏹"
    when "cleric", "priest", "healer" then "✨"
    when "necromancer", "warlock" then "💀"
    else "🛡️"
    end
  end

  # ===========================================================================
  # Opponent Stats Display
  # ===========================================================================

  # Get current user's team in this match
  # @return [String, nil] team identifier ("a", "b", etc.) or nil
  def current_user_team
    return nil unless @arena_match && current_user

    participation = @arena_match.arena_participations.find_by(user: current_user)
    participation&.team
  end

  # Get opponent's combat-relevant stats for display
  # Shows: Strength, Dexterity, Luck, Knowledge, Wisdom
  #
  # @param participation [ArenaParticipation] the participation record
  # @return [Hash] stats hash with :strength, :dexterity, :luck, :knowledge, :wisdom
  def opponent_combat_stats(participation)
    if participation.npc?
      npc_combat_stats(participation.npc_template)
    else
      character_combat_stats(participation.character)
    end
  end

  # Extract combat stats from a character
  # @param character [Character] the character
  # @return [Hash] stats hash
  def character_combat_stats(character)
    return {} unless character

    stats = character.stats
    return {} unless stats

    {
      strength: stats.get(:strength) || stats.get(:attack) || character.level * 2,
      dexterity: stats.get(:dexterity) || stats.get(:agility) || 5,
      luck: stats.get(:luck) || 5,
      knowledge: stats.get(:knowledge) || stats.get(:intelligence) || 1,
      wisdom: stats.get(:wisdom) || 1,
      attack: stats.get(:attack),
      defense: stats.get(:defense)
    }.compact
  end

  # Extract combat stats from an NPC template
  # @param npc [NpcTemplate] the NPC template
  # @return [Hash] stats hash
  def npc_combat_stats(npc)
    return {} unless npc

    # Try to get stats from NPC config
    npc_config = Game::World::ArenaNpcConfig.find_npc(npc.npc_key) if npc.npc_key.present?
    if npc_config
      config_stats = Game::World::ArenaNpcConfig.extract_stats(npc_config)
      return {
        strength: config_stats[:attack],
        dexterity: config_stats[:agility],
        luck: config_stats[:luck] || 5,
        knowledge: config_stats[:intelligence] || 1,
        wisdom: config_stats[:wisdom] || 1,
        attack: config_stats[:attack],
        defense: config_stats[:defense]
      }.compact
    end

    # Fallback to metadata or level-based stats
    level = npc.level || 1
    {
      strength: npc.metadata&.dig("base_damage") || (level * 3 + 5),
      dexterity: level + 5,
      luck: 5 + (level / 5),
      knowledge: 1,
      wisdom: 1,
      attack: npc.metadata&.dig("base_damage") || (level * 3 + 5),
      defense: level * 2 + 3
    }
  end

  # ===========================================================================
  # Turn Timeout Display
  # ===========================================================================

  # Display turn timeout countdown
  # @param match [ArenaMatch] the arena match
  # @return [ActiveSupport::SafeBuffer] HTML for timeout display
  def turn_timeout_display(match)
    return "" unless match.live? && match.current_turn_started_at

    remaining = match.seconds_until_timeout
    return "" unless remaining

    css_class = if remaining <= 10
      "timeout-critical"
    elsif remaining <= 30
      "timeout-warning"
    else
      "timeout-normal"
    end

    minutes = remaining / 60
    seconds = remaining % 60
    time_str = format("%d:%02d", minutes, seconds)

    content_tag(:div, class: "turn-timeout #{css_class}") do
      safe_join([
        content_tag(:span, "⏱️ Turn timeout: ", class: "timeout-label"),
        content_tag(:span, time_str, class: "timeout-value",
          data: {controller: "countdown", countdown_seconds_value: remaining})
      ])
    end
  end

  # ===========================================================================
  # HP Recovery Gate Display
  # ===========================================================================

  # Check if character can fight and return reason if not
  # @param character [Character] the character
  # @return [String, nil] reason why can't fight, or nil if can
  def arena_access_reason(character)
    return "Not logged in" unless character

    hp_percent = (character.current_hp.to_f / character.max_hp * 100).round
    min_hp = ArenaApplication::MIN_HP_PERCENT_FOR_ARENA

    if hp_percent < min_hp
      "Recover before fighting - you are too weakened! (#{hp_percent}% HP, need #{min_hp}%)"
    end
  end

  # Display HP recovery warning if needed
  # @param character [Character] the character
  # @return [ActiveSupport::SafeBuffer, nil] HTML warning or nil
  def hp_recovery_warning(character)
    reason = arena_access_reason(character)
    return nil unless reason

    content_tag(:div, class: "arena-warning arena-warning--hp") do
      safe_join([
        content_tag(:span, "⚠️ ", class: "warning-icon"),
        content_tag(:span, reason, class: "warning-message")
      ])
    end
  end
end
