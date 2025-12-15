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
      class: "game-btn game-btn--#{options[:style] || "primary"}",
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

  # Format vital stats as "current/max"
  def format_vital(current, max)
    "#{current.to_i}/#{max.to_i}"
  end

  # Calculate vital bar width percentage (0-100)
  def vital_bar_width(current, max)
    return 0 if max.to_i.zero?
    ((current.to_f / max) * 100).round.clamp(0, 100)
  end

  # Return icon for combat action type
  def combat_action_icon(action_type)
    case action_type.to_sym
    when :attack then "⚔️"
    when :block then "🛡️"
    when :skill then "✨"
    when :flee then "🏃"
    when :surrender then "🏳️"
    else "❓"
    end
  end

  # Return localized label for body part
  def body_part_label(body_part)
    body_part.to_s.titleize
  end

  # Return CSS class based on damage severity
  def damage_color_class(damage, max_hp)
    return "damage-normal" if max_hp.to_i.zero?

    percent = (damage.to_f / max_hp) * 100
    case percent
    when 30.. then "damage-critical"
    when 15..30 then "damage-warning"
    else "damage-normal"
    end
  end

  # Return icon for magic/skill element type
  # @param element [String, Symbol] the element or skill type
  # @return [String] emoji icon
  def magic_icon(element)
    case element.to_s
    when "fire" then "🔥"
    when "water", "ice" then "❄️"
    when "earth" then "🪨"
    when "air", "lightning" then "⚡"
    when "arcane" then "✨"
    when "heal" then "💚"
    when "shield" then "🛡️"
    when "buff" then "⬆️"
    when "debuff" then "⬇️"
    when "damage" then "⚔️"
    when "dot" then "🔥"
    when "hot" then "💖"
    when "aoe" then "💥"
    when "drain" then "🩸"
    else "🔮"
    end
  end

  # Return CSS class for combat log entry
  # @param entry [String, CombatLogEntry] the log entry
  # @return [String] CSS class name
  def entry_class_for(entry)
    return "log-entry--info" unless entry.respond_to?(:to_s)

    text = entry.to_s.downcase

    if text.include?("critical") || text.include?("crit")
      "log-entry--critical"
    elsif text.include?("damage") || text.include?("attack")
      "log-entry--damage"
    elsif text.include?("heal") || text.include?("healing")
      "log-entry--heal"
    elsif text.include?("buff")
      "log-entry--buff"
    elsif text.include?("debuff") || text.include?("reduce")
      "log-entry--debuff"
    elsif text.include?("victory") || text.include?("defeat")
      "log-entry--result"
    elsif text.include?("escape") || text.include?("flee")
      "log-entry--flee"
    else
      "log-entry--info"
    end
  end

  # ===========================================================================
  # Combat Log Entry Helpers (for _nl_combat_log.html.erb)
  # ===========================================================================

  # Return CSS class for log entry type
  def entry_type_class(entry)
    return "system" unless entry.respond_to?(:log_type) || entry.is_a?(Hash)

    log_type = entry.is_a?(Hash) ? entry[:log_type] : entry.log_type
    case log_type.to_s
    when "attack" then "attack"
    when "skill" then "skill"
    when "heal" then "heal"
    when "defeat" then "defeat"
    when "victory" then "victory"
    else "system"
    end
  end

  # Format log entry timestamp
  def format_log_time(entry)
    time = entry.respond_to?(:created_at) ? entry.created_at : Time.current
    time.strftime("%H:%M")
  end

  # Return log entry type as symbol
  def entry_type(entry)
    return :system unless entry.respond_to?(:log_type) || entry.is_a?(Hash)

    log_type = entry.is_a?(Hash) ? entry[:log_type] : entry.log_type
    log_type&.to_sym || :system
  end

  # Render combatant name with team color
  def render_combatant(entry, role)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload ||= {}

    name = payload[role.to_s] || payload[role] || "Unknown"
    team = payload["#{role}_team"] || "alpha"
    color = team == "alpha" ? "#0052A6" : "#087C20"

    "<span style='color: #{color};'><strong>#{name}</strong></span>".html_safe
  end

  # Check if attack hit
  def entry_hit?(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    result = payload["result"] || payload[:result]
    %w[hit critical].include?(result.to_s)
  end

  # Check if attack was blocked
  def entry_blocked?(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    result = payload["result"] || payload[:result]
    result.to_s == "blocked"
  end

  # Check if attack was critical
  def entry_critical?(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload["critical"] || payload[:critical]
  end

  # Get body part from entry
  def entry_body_part(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload["body_part"] || payload[:body_part] || "torso"
  end

  # Get damage from entry
  def entry_damage(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload["damage"] || payload[:damage] || 0
  end

  # Get skill name from entry
  def entry_skill_name(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload["skill"] || payload[:skill] || "Unknown Skill"
  end

  # Get element from entry
  def entry_element(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload["element"] || payload[:element] || "normal"
  end

  # Get skill amount from entry
  def entry_skill_amount(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload["amount"] || payload[:amount]
  end

  # Get amount from entry
  def entry_amount(entry)
    payload = entry.respond_to?(:payload) ? entry.payload : (entry.is_a?(Hash) ? entry[:data] : {})
    payload["amount"] || payload[:amount] || 0
  end
end
