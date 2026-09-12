# frozen_string_literal: true

module ArenaHelper
  include AlignmentHelper

  # Room type labels
  ROOM_TYPE_CONFIG = {
    help: {label: "Help Hall", description: "0-5"},
    training: {label: "Training Hall", description: "Training hall"},
    trial: {label: "Trial Hall", description: "5-33"},
    initiation: {label: "Initiation Hall", description: "9-33"},
    patron: {label: "Patron Hall", description: "16-33"},
    law: {label: "Law Hall", description: "Alignment: Law"},
    light: {label: "Light Hall", description: "Alignment: Light"},
    balance: {label: "Balance Hall", description: "Alignment: Balance"},
    chaos: {label: "Chaos Hall", description: "Alignment: Chaos"},
    dark: {label: "Dark Hall", description: "Alignment: Dark"}
  }.freeze

  # Fight type configuration
  FIGHT_TYPE_CONFIG = {
    duel: {label: "Duels"},
    team_battle: {label: "Groups"}
  }.freeze

  # Fight kind configuration
  FIGHT_KIND_CONFIG = {
    no_weapons: {label: "Unarmed (no equipment)"},
    free: {label: "Free"},
    alignment_vs_alignment: {label: "Alignment vs Alignment"},
    alignment_vs_all: {label: "Alignment vs All"},
    closed: {label: "Closed (up to 10 vs 10)"},
    no_artifacts: {label: "No Artifacts"},
    limited_artifacts: {label: "Limited Artifacts"}
  }.freeze

  # Options supported by each application mode.
  def arena_fight_kind_options(type)
    kinds = type == "team_battle" ? ArenaApplication::GROUP_KINDS : ArenaApplication::DUEL_KINDS
    kinds.map { |kind| [fight_kind_label(kind), kind] }
  end

  # Match status labels
  MATCH_STATUS_CONFIG = {
    pending: {label: "Waiting", css: "pending"},
    matching: {label: "Finding Opponent", css: "matching"},
    countdown: {label: "Starting Soon", css: "countdown"},
    live: {label: "Live", css: "live"},
    completed: {label: "Finished", css: "completed"},
    cancelled: {label: "Canceled", css: "cancelled"}
  }.freeze

  def room_type_icon(room_type)
    ROOM_TYPE_CONFIG.dig(room_type.to_sym, :label) || "Arena"
  end

  def room_type_badge(room_type)
    config = ROOM_TYPE_CONFIG[room_type.to_sym] || {label: room_type.to_s.humanize}
    content_tag(:span, config[:label], class: "room-type-badge room-type-#{room_type}", title: config[:description])
  end

  # Check if current user is participating in the match
  def current_user_participating?
    current_user_arena_participation.present?
  end

  def current_user_active_arena_participant?(match = @arena_match)
    participation = current_user_arena_participation(match)
    participation.present? && !match.participant_defeated?(participation)
  end

  # Check if current user won the match
  def current_user_won?
    return false unless @arena_match&.completed? && current_user

    current_user_arena_participation&.victory? || false
  end

  def current_user_arena_result(match = @arena_match)
    participation = current_user_arena_participation(match)
    return "ended" unless participation

    participation.result.in?(%w[victory defeat draw]) ? participation.result : "ended"
  end

  # Format fight type for display with icon
  def fight_type_label(fight_type)
    config = FIGHT_TYPE_CONFIG[fight_type.to_sym]
    config ? config[:label] : fight_type.to_s.humanize
  end

  def fight_type_with_icon(fight_type)
    config = FIGHT_TYPE_CONFIG[fight_type.to_sym] || {label: fight_type.to_s.humanize}
    config[:label]
  end

  # Format fight kind for display with icon
  def fight_kind_label(fight_kind)
    config = FIGHT_KIND_CONFIG[fight_kind.to_sym]
    config ? config[:label] : fight_kind.to_s.humanize
  end

  def fight_kind_with_icon(fight_kind)
    config = FIGHT_KIND_CONFIG[fight_kind.to_sym] || {label: fight_kind.to_s.humanize}
    config[:label]
  end

  def arena_application_rule_label(application)
    rule_value = application.metadata.to_h["neverlands_rule_value"]
    return "rule #{rule_value}" if rule_value.present?

    fight_kind_label(application.fight_kind)
  end

  def arena_application_applicant_level_gate(application)
    min = application.metadata.to_h["npc_side_level_min"] || application.enemy_level_min
    max = application.metadata.to_h["npc_side_level_max"] || application.enemy_level_max
    return "" if min.blank? && max.blank?

    "levels #{min || 0}-#{max || 33}"
  end

  def arena_application_open_side_level_gate(application)
    min = application.team_level_min || application.arena_room.level_min
    max = application.team_level_max || application.arena_room.level_max

    "levels #{min}-#{max}"
  end

  # Match status badge
  def arena_match_status_badge(status)
    config = MATCH_STATUS_CONFIG[status.to_sym] || {label: status.to_s.humanize, css: "unknown"}
    content_tag(:span, config[:label], class: "match-status match-status--#{config[:css]}")
  end

  # Application status tag
  def arena_room_status_tag(room)
    if room.has_capacity?
      content_tag(:span, "Open", class: "room-status room-status--open")
    else
      content_tag(:span, "Full", class: "room-status room-status--full")
    end
  end

  def arena_match_status_tag(match)
    arena_match_status_badge(match.status)
  end

  def arena_match_combat_log(match)
    Arena::CombatLogPresenter.rows_for(match)
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

    alignment_class = (character.alignment == current_character&.alignment) ? "ally" : "enemy"

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
      "Lvl. #{min}"
    else
      "Lvl. #{min}-#{max}"
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
    :attack_power, :defense, :armor_class, :evasion,
    :accuracy, :crushing, :endurance, :armor_penetration,
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

    names = match.arena_participations
      .where(team: match.winning_team)
      .includes(:character, :npc_template)
      .map(&:participant_name)

    names.presence&.join(", ") || "Unknown"
  end

  # Format duration in human-readable format
  # @param seconds [Integer] duration in seconds
  # @return [String] formatted duration
  def format_duration(seconds)
    return "0s" unless seconds&.positive?

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

  # Extract participant display data, including equipment-aware player maxima.
  # Resource maxima remain separate from the fight profile's magic-hit ceiling.
  # @param participation [ArenaParticipation] the participation record
  # @return [ParticipantData] structured participant data
  def participant_data(participation)
    character = participation.character
    npc_template = participation.npc_template
    is_npc = npc_template.present?

    if is_npc
      current_hp = participation.metadata&.dig("current_hp") || npc_template.health
      max_hp = participation.metadata&.dig("max_hp") || npc_template.health
      max_mp = participation.max_mp
      current_mp = participation.current_mp
      name = participation.participant_name
      level = participation.participant_level
      participant_id = "npc-participation-#{participation.id}"
    else
      current_hp = character.current_hp
      max_hp = participation.max_hp
      current_mp = character.current_mp
      max_mp = participation.max_mp
      name = character.name
      level = character.level
      participant_id = character.id
    end

    current_hp = 0 if participation.defeat?
    hp_percent = max_hp.zero? ? 0 : ((current_hp.to_f / max_hp) * 100).round(1)
    mp_percent = max_mp.zero? ? 0 : ((current_mp.to_f / max_mp) * 100).round(1)

    # Get stats (for opponent display)
    stats = if is_npc
      npc_combat_stats(participation)
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
      strength: stats[:strength],
      dexterity: stats[:dexterity],
      luck: stats[:luck],
      knowledge: stats[:knowledge],
      wisdom: stats[:wisdom],
      attack_power: stats[:attack_power] || stats[:attack] || 0,
      defense: stats[:defense] || 0,
      armor_class: stats[:armor_class],
      evasion: stats[:evasion],
      accuracy: stats[:accuracy],
      crushing: stats[:crushing],
      endurance: stats[:endurance],
      armor_penetration: stats[:armor_penetration]
    )
  end

  # Check if participant is dead
  # @param participation [ArenaParticipation] the participation record
  # @return [Boolean]
  def participant_dead?(participation)
    !participation.combat_alive?
  end

  # Generate avatar tag for arena participant.
  # NPC images come only from explicit NPC metadata; player portraits use the
  # neutral paper-doll placeholder until a source-backed portrait system exists.
  #
  # @param participation [ArenaParticipation] the participation record
  # @param size [Symbol] :small, :medium, or :large
  # @return [ActiveSupport::SafeBuffer] HTML span element with avatar
  def participation_avatar_tag(participation, size: :medium, **options)
    return npc_participation_avatar_tag(participation, size:, **options) if participation.npc?

    character_avatar_tag(participation.character, size:, **options)
  end

  # Equipment shown around a combatant uses the same authoritative equipped
  # inventory records as Profile and Inventory. NPC equipment uses separate
  # captured content and never creates player-owned inventory records.
  def arena_fighter_equipment(participation)
    inventory = participation.character&.inventory
    return {} unless inventory

    inventory.inventory_items.select(&:equipped?).index_by do |item|
      item.equipment_slot.to_s.presence || item.item_template&.slot.to_s
    end
  end

  def arena_npc_equipment(participation)
    participation.npc? ? participation.npc_combat_data.fetch("equipment", {}) : {}
  end

  # ===========================================================================
  # Opponent Stats Display
  # ===========================================================================

  # Get current user's team in this match
  # @return [String, nil] team identifier ("a", "b", etc.) or nil
  def current_user_team
    return nil unless @arena_match && current_user

    current_user_arena_participation&.team
  end

  def current_user_arena_participation(match = @arena_match)
    return nil unless match && current_user

    unless match.equal?(@arena_match)
      return match.arena_participations.find_by(user: current_user)
    end

    return @current_user_arena_participation if defined?(@current_user_arena_participation)

    if defined?(@participations) && @participations
      @current_user_arena_participation = @participations.find do |participation|
        participation.user_id == current_user.id
      end
    else
      @current_user_arena_participation = match.arena_participations.find_by(user_id: current_user.id)
    end
  end

  def current_user_pending_arena_turn?(match = @arena_match)
    participation = current_user_arena_participation(match)
    return false unless participation&.combat_alive?

    pending_turn = participation.metadata&.dig("pending_turn")
    return false unless pending_turn.present?

    pending_turn["turn_number"].to_i == (match.current_turn_number || 1).to_i
  end

  def current_user_finished_arena_match?(match = @arena_match)
    participation = current_user_arena_participation(match)
    participation&.metadata&.dig("finished_at").present?
  end

  def arena_combat_profile(participation = current_user_arena_participation)
    return default_arena_combat_profile unless participation

    Arena::CombatProfile.for_participation(participation, persist: true)
  end

  def arena_action_point_limit(participation = current_user_arena_participation)
    arena_combat_profile(participation).fetch("ap_limit")
  end

  def arena_attack_options(participation = current_user_arena_participation, combat_config = Game::Combat::ActionCatalog.config)
    profile = arena_combat_profile(participation)

    Game::Combat::ActionCatalog.attack_options_for_profile(profile, combat_config).each_with_object({}) do |(key, config), options|
      option_config = config.deep_dup
      case key.to_s
      when "simple"
        option_config["action_cost"] = profile["simple_attack_cost"]
      when "aimed"
        option_config["action_cost"] = profile["aimed_attack_cost"]
      end
      options[key] = option_config
    end
  end

  def arena_block_options(participation = current_user_arena_participation, combat_config = Game::Combat::ActionCatalog.config)
    profile = arena_combat_profile(participation)
    Game::Combat::ActionCatalog.block_options_for_profile(profile, combat_config)
  end

  def arena_timeout_claim_available?(match = @arena_match)
    match&.live? && match.turn_timed_out? && current_user_pending_arena_turn?(match)
  end

  # Get opponent's combat-relevant stats for display
  # Shows: Strength, Dexterity, Luck, and Knowledge.
  #
  # @param participation [ArenaParticipation] the participation record
  # @return [Hash] stats hash with :strength, :dexterity, :luck, and :knowledge
  def opponent_combat_stats(participation)
    if participation.npc?
      npc_combat_stats(participation)
    else
      character_combat_stats(participation.character)
    end
  end

  # Project effective primary stats and distinct equipment combat modifiers.
  # The legacy endurance field displays Fortitude, never Health or resistance;
  # displayed modifiers do not imply unverified probability formulas.
  # @param character [Character] the character
  # @return [Hash] stats hash
  def character_combat_stats(character)
    return {} unless character

    stats = character.stats
    return {} unless stats

    {
      strength: stats.get(:strength),
      dexterity: stats.get(:dexterity),
      luck: stats.get(:luck),
      knowledge: stats.get(:intelligence),
      attack: character.attack_power,
      attack_power: character.attack_power,
      defense: character.defense,
      armor_class: character.armor_class,
      evasion: character.dodge_bonus,
      accuracy: character.accuracy_bonus,
      crushing: character.crushing_percent,
      endurance: character.fortitude_percent,
      armor_penetration: character.armor_pierce_percent
    }.compact
  end

  # Extract combat stats from an NPC template
  # @param npc [NpcTemplate] the NPC template
  # @return [Hash] stats hash
  def npc_combat_stats(participation)
    return {} unless participation

    data = participation.is_a?(ArenaParticipation) ? participation.npc_combat_data : participation.metadata.to_h
    data.fetch("display_stats", {}).symbolize_keys
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
        content_tag(:span, "Timeout: ", class: "timeout-label"),
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
    return "No character" unless character

    hp_percent = (character.current_hp.to_f / character.max_hp * 100).round
    min_hp = ArenaApplication::MIN_HP_PERCENT_FOR_ARENA

    if hp_percent < min_hp
      "Recover before fighting: #{hp_percent}% HP, need #{min_hp}%"
    end
  end

  def default_arena_combat_profile
    seed = Arena::CombatProfile::DEFAULT_PHYSICAL_ATTACK_SEED
    {
      "ap_limit" => Arena::CombatProfile::DEFAULT_AP_LIMIT,
      "physical_attack_cost_seed" => seed,
      "simple_attack_cost" => seed,
      "aimed_attack_cost" => seed + Arena::CombatProfile::AIMED_ATTACK_SURCHARGE,
      "max_magic_mana" => 0,
      "block_table" => "normal",
      "injected_attack_keys" => [],
      "injected_block_keys" => []
    }
  end

  # Display HP recovery warning if needed
  # @param character [Character] the character
  # @return [ActiveSupport::SafeBuffer, nil] HTML warning or nil
  def hp_recovery_warning(character)
    reason = arena_access_reason(character)
    return nil unless reason

    content_tag(:div, class: "arena-warning arena-warning--hp") do
      safe_join([
        content_tag(:span, "Warning: ", class: "warning-icon"),
        content_tag(:span, reason, class: "warning-message")
      ])
    end
  end
end
