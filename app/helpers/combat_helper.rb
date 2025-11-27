# frozen_string_literal: true

# Helpers for combat views
module CombatHelper
  SKILL_ICONS = {
    "damage" => "⚔️",
    "heal" => "💚",
    "buff" => "⬆️",
    "debuff" => "⬇️",
    "dot" => "🔥",
    "hot" => "💖",
    "aoe" => "💥",
    "drain" => "🩸",
    "shield" => "🛡️"
  }.freeze

  def skill_icon(skill_type)
    SKILL_ICONS[skill_type.to_s] || "✨"
  end

  def skill_tooltip(skill)
    parts = [skill[:name]]

    if skill[:cost][:mp].to_i.positive?
      parts << "Cost: #{skill[:cost][:mp] || skill[:cost]["mp"]} MP"
    end

    if skill[:cooldown].to_i.positive?
      parts << "Cooldown: #{skill[:cooldown]}s"
    end

    effects = skill[:effects]
    if effects.present?
      if effects["base_damage"] || effects[:base_damage]
        parts << "Damage: #{effects["base_damage"] || effects[:base_damage]}"
      end
      if effects["base_heal"] || effects[:base_heal]
        parts << "Heal: #{effects["base_heal"] || effects[:base_heal]}"
      end
    end

    parts.join(" | ")
  end

  def combat_action_button(label, action_type, options = {})
    button_to label,
      combat_action_path(action_type: action_type),
      method: :post,
      class: "game-btn game-btn--#{options[:style] || 'primary'}",
      data: {turbo: true}
  end

  def hp_bar_width(current, max)
    return 0 if max.to_i.zero?

    ((current.to_f / max) * 100).round(1)
  end

  def hp_bar_color(current, max)
    percent = hp_bar_width(current, max)
    case percent
    when 0..25 then "critical"
    when 26..50 then "low"
    when 51..75 then "medium"
    else "full"
    end
  end
end
