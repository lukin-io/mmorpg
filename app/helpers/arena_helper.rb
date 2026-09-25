# frozen_string_literal: true

module ArenaHelper
  include AlignmentHelper

  ROOM_TYPES = %i[help training trial initiation patron law light balance chaos dark].freeze
  FIGHT_TYPES = %i[duel team_battle sacrifice].freeze
  FIGHT_KINDS = %i[no_weapons free alignment_vs_alignment no_artifacts limited_artifacts].freeze
  MATCH_STATUS_CSS = {
    pending: "pending",
    matching: "matching",
    countdown: "countdown",
    live: "live",
    completed: "completed",
    cancelled: "cancelled"
  }.freeze

  def room_type_icon(room_type)
    I18n.t("arena.rooms.#{room_type}.label", default: I18n.t("arena.title"))
  end

  def room_type_badge(room_type)
    label = I18n.t("arena.rooms.#{room_type}.label", default: room_type.to_s.tr("_", " "))
    description = I18n.t("arena.rooms.#{room_type}.description", default: "")
    content_tag(:span, label, class: "room-type-badge room-type-#{room_type}", title: description)
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

  def fight_type_label(fight_type)
    I18n.t("arena.fight_types.#{fight_type}", default: fight_type.to_s.tr("_", " "))
  end

  def fight_type_with_icon(fight_type)
    fight_type_label(fight_type)
  end

  def fight_kind_label(fight_kind)
    I18n.t("arena.fight_kinds.#{fight_kind}", default: fight_kind.to_s.tr("_", " "))
  end

  def fight_kind_with_icon(fight_kind)
    fight_kind_label(fight_kind)
  end

  def arena_application_rule_label(application)
    rule_value = application.metadata.to_h["neverlands_rule_value"]
    return I18n.t("arena.rule", value: rule_value) if rule_value.present?

    fight_kind_label(application.fight_kind)
  end

  def arena_application_applicant_level_gate(application)
    min = application.metadata.to_h["npc_side_level_min"] || application.enemy_level_min
    max = application.metadata.to_h["npc_side_level_max"] || application.enemy_level_max
    return "" if min.blank? && max.blank?

    I18n.t("arena.levels", min: min || 0, max: max || 33)
  end

  def arena_application_open_side_level_gate(application)
    min = application.team_level_min || application.arena_room.level_min
    max = application.team_level_max || application.arena_room.level_max

    I18n.t("arena.levels", min: min, max: max)
  end

  def arena_match_status_badge(status)
    label = I18n.t("arena.match_status.#{status}", default: status.to_s.tr("_", " "))
    css = MATCH_STATUS_CSS[status.to_sym] || "unknown"
    content_tag(:span, label, class: "match-status match-status--#{css}")
  end

  def arena_room_status_tag(room)
    if room.has_capacity?
      content_tag(:span, I18n.t("arena.open"), class: "room-status room-status--open")
    else
      content_tag(:span, I18n.t("arena.full"), class: "room-status room-status--full")
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
    return I18n.t("arena.waiting_opponent") unless character

    alignment_class = (character.alignment == current_character&.alignment) ? "ally" : "enemy"

    content_tag(:div, class: "opponent-display opponent-display--#{alignment_class}") do
      safe_join([
        alignment_icons(character),
        content_tag(:strong, character.name),
        content_tag(:span, " [#{character.level}]", class: "opponent-level")
      ])
    end
  end

  def level_range_display(room)
    min = room.respond_to?(:level_min) ? room.level_min : room.min_level
    max = room.respond_to?(:level_max) ? room.level_max : room.max_level

    I18n.t("arena.levels", min: min, max: max)
  end

  def arena_match_trauma_value(match)
    percent = match.try(:trauma_percent).presence || match.metadata.to_h["trauma_percent"].presence
    return I18n.t("game.fight.trauma_value", percent:) if percent.present?

    I18n.t("game.fight.trauma_unknown")
  end

  def fight_option_cost(action_cost, mana_cost = 0)
    mana = mana_cost.to_i
    return action_cost.to_s if mana <= 0

    I18n.t("game.fight.option_cost_with_mana", ap: action_cost, mana:)
  end

  def fight_action_display_name(key, config = {})
    explicit = config.is_a?(Hash) ? config["name"].presence || config[:name].presence : nil
    return explicit if explicit.present?

    I18n.t(
      "game.combat.attack_types.#{key}",
      default: I18n.t("game.combat.block_types.#{key}", default: key.to_s.tr("_", " "))
    )
  end

  # ===========================================================================
  # Participant Data Helpers
  # ===========================================================================

  # Struct to hold participant display data
  ParticipantData = Struct.new(
    :name, :level, :id, :is_npc,
    :current_hp, :max_hp, :current_mp, :max_mp,
    :hp_percent, :mp_percent,
    :strength, :dexterity, :luck, :knowledge,
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
    return I18n.t("arena.draw") unless match.winning_team

    names = match.arena_participations
      .where(team: match.winning_team)
      .includes(:character, :npc_template)
      .map(&:participant_name)

    names.presence&.join(", ") || I18n.t("arena.unknown")
  end

  # Format duration in human-readable format
  # @param seconds [Integer] duration in seconds
  # @return [String] formatted duration
  def format_duration(seconds)
    return I18n.t("game.fight.duration_zero") unless seconds&.positive?

    if seconds < 60
      I18n.t("game.fight.duration_seconds", count: seconds)
    elsif seconds < 3600
      minutes = seconds / 60
      secs = seconds % 60
      if secs.positive?
        I18n.t("game.fight.duration_minutes_seconds", minutes:, seconds: secs)
      else
        I18n.t("game.fight.duration_minutes", count: minutes)
      end
    else
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      if minutes.positive?
        I18n.t("game.fight.duration_hours_minutes", hours:, minutes:)
      else
        I18n.t("game.fight.duration_hours", count: hours)
      end
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
      name = participation.participant_name
      level = participation.participant_level
      participant_id = "npc-participation-#{participation.id}"
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
      attack_power: stats[:attack_power] || stats[:attack] || 0,
      defense: stats[:defense] || 0,
      armor_class: stats[:armor_class] || stats[:defense] || 0,
      evasion: stats[:evasion] || stats[:dexterity].to_i / 2,
      accuracy: stats[:accuracy] || stats[:dexterity].to_i,
      crushing: stats[:crushing] || stats[:luck].to_i,
      endurance: stats[:endurance] || stats[:vitality].to_i,
      armor_penetration: stats[:armor_penetration] || 0
    )
  end

  # Check if participant is dead
  # @param participation [ArenaParticipation] the participation record
  # @return [Boolean]
  def participant_dead?(participation)
    data = participant_data(participation)
    data.current_hp <= 0
  end

  # Generate avatar tag for arena participant.
  # NPC images come only from explicit NPC metadata; player portraits use the
  # neutral paper-doll placeholder until a source-backed portrait system exists.
  #
  # @param participation [ArenaParticipation] the participation record
  # @param size [Symbol] :small, :medium, or :large
  # @return [ActiveSupport::SafeBuffer] HTML span element with avatar
  def participation_avatar_tag(participation, size: :medium, **options)
    return npc_avatar_tag(participation.npc_template, size:, **options) if participation.npc?

    character_avatar_tag(participation.character, size:, **options)
  end

  # Equipment shown around a combatant uses the same authoritative equipped
  # inventory records as Profile and Inventory. NPCs deliberately return an
  # empty slot set because their visible equipment is part of captured art.
  def arena_fighter_equipment(participation)
    inventory = participation.character&.inventory
    return {} unless inventory

    inventory.inventory_items.select(&:equipped?).index_by do |item|
      item.equipment_slot.to_s.presence || item.item_template&.slot.to_s
    end
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
    return false unless participation

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
      strength: stats.get(:strength),
      dexterity: stats.get(:dexterity),
      luck: stats.get(:luck),
      knowledge: stats.get(:intelligence),
      attack: character.attack_power,
      attack_power: character.attack_power,
      defense: character.defense,
      armor_class: character.defense,
      evasion: character.agility / 2,
      accuracy: stats.get(:dexterity).to_i,
      crushing: character.critical_chance,
      endurance: stats.get(:vitality).to_i,
      armor_penetration: character.equipment_family_breakdown.sum { |item| item[:family] == "axe" ? item[:attack] / 5 : 0 }
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
        attack: config_stats[:attack],
        attack_power: config_stats[:attack],
        defense: config_stats[:defense],
        armor_class: config_stats[:defense],
        evasion: config_stats[:agility].to_i / 2,
        accuracy: config_stats[:agility],
        crushing: config_stats[:crit_chance] || 5,
        endurance: config_stats[:hp],
        armor_penetration: config_stats[:armor_penetration] || 0
      }.compact
    end

    {
      strength: npc.combat_stat(:attack),
      dexterity: npc.combat_stat(:agility),
      luck: npc.combat_stat(:luck),
      knowledge: 0,
      attack: npc.combat_stat(:attack),
      attack_power: npc.combat_stat(:attack),
      defense: npc.combat_stat(:defense),
      armor_class: npc.combat_stat(:defense),
      evasion: npc.combat_stat(:evasion),
      accuracy: npc.combat_stat(:accuracy),
      crushing: npc.combat_stat(:crit_chance),
      endurance: npc.health,
      armor_penetration: 0
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
        content_tag(:span, "#{I18n.t("arena.timeout_label")}: ", class: "timeout-label"),
        content_tag(:span, time_str, class: "timeout-value",
          data: {controller: "countdown", countdown_seconds_value: remaining})
      ])
    end
  end

  def arena_access_reason(character)
    return I18n.t("arena.no_character") unless character

    hp_percent = (character.current_hp.to_f / character.max_hp * 100).round
    min_hp = ArenaApplication::MIN_HP_PERCENT_FOR_ARENA

    if hp_percent < min_hp
      I18n.t("arena.recover_hp", hp: hp_percent, min: min_hp)
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
        content_tag(:span, "#{I18n.t("arena.warning")}: ", class: "warning-icon"),
        content_tag(:span, reason, class: "warning-message")
      ])
    end
  end
end
