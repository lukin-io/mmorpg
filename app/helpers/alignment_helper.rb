# frozen_string_literal: true

module AlignmentHelper
  ALIGNMENT_ICONS = Character::ALIGNMENT_LABELS.transform_keys(&:to_sym).freeze

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
