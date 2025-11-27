# frozen_string_literal: true

# Helpers for dungeon views.
module DungeonsHelper
  DUNGEON_ICONS = {
    "cave" => "🕳️",
    "castle" => "🏰",
    "forest" => "🌲",
    "crypt" => "⚰️",
    "temple" => "🛕",
    "mine" => "⛏️",
    "tower" => "🗼",
    "ruins" => "🏛️"
  }.freeze

  def dungeon_icon(template)
    DUNGEON_ICONS[template.dungeon_type] || "🏰"
  end

  def item_icon(item_key)
    case item_key
    when /sword|blade|weapon/ then "⚔️"
    when /armor|plate|mail/ then "🛡️"
    when /potion|elixir/ then "🧪"
    when /ring|amulet|jewel/ then "💍"
    when /scroll|tome|book/ then "📜"
    else "📦"
    end
  end

  def can_enter_dungeon?(template)
    return false unless current_party
    return false if current_character.level < template.min_level

    true
  end

  def current_party
    @current_party ||= current_user.parties
      .joins(:party_memberships)
      .where(party_memberships: {user_id: current_user.id, status: :active})
      .first
  end

  def dungeon_lock_reason(template)
    return "Need a party to enter" unless current_party
    return "Level #{template.min_level} required" if current_character.level < template.min_level
    return "Quest required" if template.required_quest.present? && !quest_completed?(template.required_quest)

    "Cannot enter"
  end

  def quest_completed?(quest_key)
    current_character.quest_assignments.joins(:quest).exists?(quests: {key: quest_key}, status: :completed)
  end
end
