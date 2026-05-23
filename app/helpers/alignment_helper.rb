# frozen_string_literal: true

module AlignmentHelper
  ALIGNMENT_ICONS = Character::ALIGNMENT_LABELS.transform_keys(&:to_sym).freeze

  FIGHT_TYPE_ICONS = {
    duel: "Duel",
    group: "Group",
    sacrifice: "Free-for-All",
    unarmed: "Unarmed",
    alignment_vs_alignment: "Alignment vs Alignment"
  }.freeze

  FIGHT_KIND_ICONS = {
    no_weapons: "Bare Hands",
    no_artifacts: "No Magic Items",
    limited_artifacts: "Limited Equipment",
    free: "All Equipment",
    clan_vs_clan: "Clan vs Clan",
    alignment_vs_alignment: "Alignment vs Alignment"
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
    arena: "Arena"
  }.freeze

  def alignment_icon(alignment)
    ALIGNMENT_ICONS[alignment.to_sym] || "None"
  end

  # Full alignment badge for a character
  def alignment_badge(character, _show_chaos: false)
    return "" unless character

    content_tag(:span, character.alignment_label, class: "alignment-badge alignment-#{character.alignment}")
  end

  # Compact alignment display (just icons)
  def alignment_icons(character)
    return "" unless character

    content_tag(:span, class: "alignment-icons") do
      content_tag(:span, alignment_icon(character.alignment), title: character.alignment_label, class: "alignment-icon")
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
  def character_nameplate(character, show_level: true)
    return "" unless character

    parts = []
    parts << alignment_icons(character)
    parts << content_tag(:strong, character.name, class: "character-name")
    parts << content_tag(:span, "[#{character.level}]", class: "character-level") if show_level

    content_tag(:span, safe_join(parts), class: "character-nameplate")
  end
end
