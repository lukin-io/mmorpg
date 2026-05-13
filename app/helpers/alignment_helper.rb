# frozen_string_literal: true

# Helper for displaying alignment labels throughout the game.
#
module AlignmentHelper
  FACTION_ICONS = {
    alliance: "Alliance",
    rebellion: "Rebellion",
    neutral: "Neutral"
  }.freeze

  ALIGNMENT_TIER_ICONS = {
    absolute_darkness: "Absolute Darkness",
    true_darkness: "True Darkness",
    child_of_darkness: "Child of Darkness",
    twilight_walker: "Twilight Walker",
    neutral: "Neutral",
    dawn_seeker: "Dawn Seeker",
    child_of_light: "Child of Light",
    true_light: "True Light",
    celestial: "Celestial"
  }.freeze

  CHAOS_TIER_ICONS = {
    lawful: "Lawful",
    balanced: "Balanced",
    chaotic: "Chaotic",
    absolute_chaos: "Absolute Chaos"
  }.freeze

  FIGHT_TYPE_ICONS = {
    duel: "Duel",
    group: "Group",
    sacrifice: "Free-for-All",
    unarmed: "Unarmed",
    clan_vs_clan: "Clan vs Clan",
    faction_vs_faction: "Faction vs Faction"
  }.freeze

  FIGHT_KIND_ICONS = {
    no_weapons: "Bare Hands",
    no_artifacts: "No Magic Items",
    limited_artifacts: "Limited Equipment",
    free: "All Equipment",
    clan_vs_clan: "Clan vs Clan",
    faction_vs_faction: "Faction vs Faction"
  }.freeze

  TIMEOUT_ICONS = {
    120 => "2m",
    180 => "3m",
    240 => "4m",
    300 => "5m"
  }.freeze

  TRAUMA_ICONS = {
    10 => {text: "Low", label: "Low"},
    30 => {text: "Medium", label: "Medium"},
    50 => {text: "High", label: "High"},
    80 => {text: "Very High", label: "Very High"},
    100 => {text: "Extreme", label: "Extreme"}
  }.freeze

  LOCATION_ICONS = {
    city: "City",
    village: "Village",
    nature: "Nature",
    arena: "Arena",
    guild_hall: "Guild Hall"
  }.freeze

  # Get faction icon
  def faction_icon(faction)
    FACTION_ICONS[faction.to_sym] || "Neutral"
  end

  # Get alignment tier icon
  def alignment_tier_icon(tier)
    ALIGNMENT_TIER_ICONS[tier.to_sym] || "Neutral"
  end

  # Get chaos tier icon
  def chaos_tier_icon(tier)
    CHAOS_TIER_ICONS[tier.to_sym] || "Lawful"
  end

  # Full alignment badge for a character
  def alignment_badge(character, show_chaos: false)
    return "" unless character

    parts = [
      faction_icon(character.faction_alignment),
      character.alignment_tier_name
    ]

    parts << "(#{character.chaos_tier_data[:name]})" if show_chaos && character.chaos_score.to_i > 0

    content_tag(:span, parts.join(" "), class: "alignment-badge alignment-#{character.alignment_tier}")
  end

  # Compact alignment display (just icons)
  def alignment_icons(character)
    return "" unless character

    content_tag(:span, class: "alignment-icons") do
      safe_join([
        content_tag(:span, faction_icon(character.faction_alignment), title: character.faction_alignment.humanize, class: "faction-icon"),
        content_tag(:span, character.alignment_tier_name, title: character.alignment_tier_name, class: "tier-icon")
      ])
    end
  end

  # Fight type icon and label
  def fight_type_badge(fight_type)
    label = fight_type.to_s.humanize
    content_tag(:span, label, class: "fight-type-badge fight-type-#{fight_type}")
  end

  # Fight kind icon and label
  def fight_kind_badge(fight_kind)
    label = fight_kind.to_s.humanize
    content_tag(:span, label, class: "fight-kind-badge fight-kind-#{fight_kind}")
  end

  # Timeout display with icon
  def timeout_badge(seconds)
    label = TIMEOUT_ICONS[seconds.to_i] || "#{seconds / 60}m"
    content_tag(:span, label, class: "timeout-badge", title: "Turn timeout: #{seconds} seconds")
  end

  # Trauma level display with icon
  def trauma_badge(percent)
    data = TRAUMA_ICONS[percent.to_i] || {text: "Low", label: "Low"}
    content_tag(:span, data[:label], class: "trauma-badge trauma-#{data[:label].downcase.tr(" ", "-")}", title: "Trauma: #{percent}%")
  end

  # Location type icon
  def location_icon(location_type)
    LOCATION_ICONS[location_type.to_sym] || "Location"
  end

  # Full fight settings display
  def fight_settings_display(fight_type: nil, fight_kind: nil, timeout: nil, trauma: nil)
    parts = []
    parts << fight_type_icon_only(fight_type) if fight_type
    parts << fight_kind_icon_only(fight_kind) if fight_kind
    parts << timeout_icon_only(timeout) if timeout
    parts << trauma_icon_only(trauma) if trauma

    content_tag(:span, safe_join(parts, " "), class: "fight-settings")
  end

  # Icon-only versions for compact display
  def fight_type_icon_only(fight_type)
    label = FIGHT_TYPE_ICONS[fight_type.to_sym] || fight_type.to_s.humanize
    content_tag(:span, label, class: "fight-icon", title: fight_type.to_s.humanize)
  end

  def fight_kind_icon_only(fight_kind)
    label = FIGHT_KIND_ICONS[fight_kind.to_sym] || fight_kind.to_s.humanize
    content_tag(:span, label, class: "fight-icon", title: fight_kind.to_s.humanize)
  end

  def timeout_icon_only(seconds)
    minutes = (seconds.to_i / 60)
    content_tag(:span, "#{minutes}m", class: "timeout-icon", title: "#{minutes} minutes")
  end

  def trauma_icon_only(percent)
    data = TRAUMA_ICONS[percent.to_i] || {text: "Low", label: "Low"}
    content_tag(:span, data[:label], class: "trauma-icon", title: "#{data[:label]} trauma (#{percent}%)")
  end

  # Character nameplate with alignment icons
  def character_nameplate(character, show_level: true, show_clan: false)
    return "" unless character

    parts = []
    parts << alignment_icons(character)
    parts << content_tag(:strong, character.name, class: "character-name")
    parts << content_tag(:span, "[#{character.level}]", class: "character-level") if show_level

    if show_clan && character.clan.present?
      parts << content_tag(:span, " #{character.clan.name}", class: "character-clan")
    end

    content_tag(:span, safe_join(parts), class: "character-nameplate")
  end
end
