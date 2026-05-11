# frozen_string_literal: true

# Helper for displaying alignment icons and labels throughout the game.
#
# Usage:
#   alignment_badge(character) # => "<span class='alignment-badge'>🛡️ ✨ True Light</span>"
#   faction_icon(:alliance)    # => "🛡️"
#
module AlignmentHelper
  # Faction icons (base alignment choice)
  FACTION_ICONS = {
    alliance: "🛡️",
    rebellion: "⚔️",
    neutral: "🏳️"
  }.freeze

  # Alignment tier icons (based on alignment_score)
  ALIGNMENT_TIER_ICONS = {
    absolute_darkness: "🖤",
    true_darkness: "⬛",
    child_of_darkness: "🌑",
    twilight_walker: "🌘",
    neutral: "☯️",
    dawn_seeker: "🌒",
    child_of_light: "🌕",
    true_light: "✨",
    celestial: "👼"
  }.freeze

  # Chaos tier icons
  CHAOS_TIER_ICONS = {
    lawful: "⚖️",
    balanced: "🔄",
    chaotic: "🔥",
    absolute_chaos: "💥"
  }.freeze

  # Fight type icons
  FIGHT_TYPE_ICONS = {
    duel: "⚔️",
    group: "👥",
    sacrifice: "💀",
    unarmed: "🥊",
    clan_vs_clan: "🏰",
    faction_vs_faction: "⚔️"
  }.freeze

  # Fight kind icons
  FIGHT_KIND_ICONS = {
    no_weapons: "🥊",
    no_artifacts: "🚫",
    limited_artifacts: "⚠️",
    free: "✅",
    clan_vs_clan: "🏰",
    faction_vs_faction: "🎌"
  }.freeze

  # Timeout icons (duration in seconds)
  TIMEOUT_ICONS = {
    120 => "⏱️2️⃣",
    180 => "⏱️3️⃣",
    240 => "⏱️4️⃣",
    300 => "⏱️5️⃣"
  }.freeze

  # Trauma level icons
  TRAUMA_ICONS = {
    10 => {emoji: "💚", label: "Low"},
    30 => {emoji: "💛", label: "Medium"},
    50 => {emoji: "🧡", label: "High"},
    80 => {emoji: "❤️", label: "Very High"},
    100 => {emoji: "💔", label: "Extreme"}
  }.freeze

  # Location type icons
  LOCATION_ICONS = {
    city: "🏰",
    village: "🏘️",
    nature: "🌲",
    dungeon: "🗝️",
    arena: "🏟️",
    guild_hall: "🏛️"
  }.freeze

  # Get faction icon
  def faction_icon(faction)
    FACTION_ICONS[faction.to_sym] || "🏳️"
  end

  # Get alignment tier icon
  def alignment_tier_icon(tier)
    ALIGNMENT_TIER_ICONS[tier.to_sym] || "☯️"
  end

  # Get chaos tier icon
  def chaos_tier_icon(tier)
    CHAOS_TIER_ICONS[tier.to_sym] || "⚖️"
  end

  # Full alignment badge for a character
  def alignment_badge(character, show_chaos: false)
    return "" unless character

    parts = [
      faction_icon(character.faction_alignment),
      character.alignment_emoji,
      character.alignment_tier_name
    ]

    parts << "(#{character.chaos_emoji})" if show_chaos && character.chaos_score.to_i > 0

    content_tag(:span, parts.join(" "), class: "alignment-badge alignment-#{character.alignment_tier}")
  end

  # Compact alignment display (just icons)
  def alignment_icons(character)
    return "" unless character

    content_tag(:span, class: "alignment-icons") do
      safe_join([
        content_tag(:span, faction_icon(character.faction_alignment), title: character.faction_alignment.humanize, class: "faction-icon"),
        content_tag(:span, character.alignment_emoji, title: character.alignment_tier_name, class: "tier-icon")
      ])
    end
  end

  # Fight type icon and label
  def fight_type_badge(fight_type)
    icon = FIGHT_TYPE_ICONS[fight_type.to_sym] || "⚔️"
    label = fight_type.to_s.humanize
    content_tag(:span, "#{icon} #{label}", class: "fight-type-badge fight-type-#{fight_type}")
  end

  # Fight kind icon and label
  def fight_kind_badge(fight_kind)
    icon = FIGHT_KIND_ICONS[fight_kind.to_sym] || "⚔️"
    label = fight_kind.to_s.humanize
    content_tag(:span, "#{icon} #{label}", class: "fight-kind-badge fight-kind-#{fight_kind}")
  end

  # Timeout display with icon
  def timeout_badge(seconds)
    icon = TIMEOUT_ICONS[seconds.to_i] || "⏱️"
    content_tag(:span, "#{icon} #{seconds / 60}min", class: "timeout-badge", title: "Turn timeout: #{seconds} seconds")
  end

  # Trauma level display with icon
  def trauma_badge(percent)
    data = TRAUMA_ICONS[percent.to_i] || {emoji: "💚", label: "Low"}
    content_tag(:span, "#{data[:emoji]} #{data[:label]}", class: "trauma-badge trauma-#{data[:label].downcase.tr(" ", "-")}", title: "Trauma: #{percent}%")
  end

  # Location type icon
  def location_icon(location_type)
    LOCATION_ICONS[location_type.to_sym] || "📍"
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
    icon = FIGHT_TYPE_ICONS[fight_type.to_sym] || "⚔️"
    content_tag(:span, icon, class: "fight-icon", title: fight_type.to_s.humanize)
  end

  def fight_kind_icon_only(fight_kind)
    icon = FIGHT_KIND_ICONS[fight_kind.to_sym] || "⚔️"
    content_tag(:span, icon, class: "fight-icon", title: fight_kind.to_s.humanize)
  end

  def timeout_icon_only(seconds)
    minutes = (seconds.to_i / 60)
    emoji = ["0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣"][minutes] || "⏱️"
    content_tag(:span, "⏱️#{emoji}", class: "timeout-icon", title: "#{minutes} minutes")
  end

  def trauma_icon_only(percent)
    data = TRAUMA_ICONS[percent.to_i] || {emoji: "💚", label: "Low"}
    content_tag(:span, data[:emoji], class: "trauma-icon", title: "#{data[:label]} trauma (#{percent}%)")
  end

  # Character nameplate with alignment icons
  def character_nameplate(character, show_level: true, show_clan: false)
    return "" unless character

    parts = []
    parts << alignment_icons(character)
    parts << content_tag(:strong, character.name, class: "character-name")
    parts << content_tag(:span, "[#{character.level}]", class: "character-level") if show_level

    if show_clan && character.clan.present?
      parts << content_tag(:span, " 🏰#{character.clan.name}", class: "character-clan")
    end

    content_tag(:span, safe_join(parts), class: "character-nameplate")
  end
end
