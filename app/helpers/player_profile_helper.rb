# frozen_string_literal: true

module PlayerProfileHelper
  def profile_location(character)
    position = character.position
    return "Unknown" unless position

    active_match = profile_active_arena_match(character)
    if active_match
      sublocation = active_match.arena_room&.name || "Arena"
      return safe_join([
        ERB::Util.html_escape(position.zone&.name || "Unknown"),
        " [ ",
        link_to("in combat", public_fight_log_path(active_match), class: "nl-profile-fight-link"),
        " ]",
        tag.br,
        ERB::Util.html_escape(sublocation)
      ])
    end

    [position.zone&.name, "[#{position.x}, #{position.y}]"].compact.join(" ")
  end

  def profile_skill_level(character, key)
    character.passive_skill_level(key).to_s.rjust(3, "0")
  end

  def profile_attack_cost
    Game::Combat::ActionCatalog.attack_cost("simple")
  rescue NameError, KeyError, NoMethodError
    45
  end

  # Primary stats with the character's own value (base + allocated) and the
  # delta contributed by equipped items, matching the captured profile surface.
  def profile_primary_stats(character)
    effective = character.stats
    Character::PRIMARY_STATS.map do |key|
      own = character.base_primary_stat_value(key)
      own += character.level.to_i / 2 if key == :strength && character.owns_perk?(:more_strength)
      total = effective.get(key).to_i

      {key: key, label: Character.stat_label(key), base: own, equipment: total - own, total: total}
    end
  end

  # Derived combat/equipment values shown in the profile capture.
  def profile_combat_stats(character)
    {
      "Attack" => character.attack_power,
      "Defense" => character.defense,
      "Critical chance" => "#{character.critical_chance}%",
      "Action points" => character.max_action_points,
      "Attack cost" => profile_attack_cost,
      "Armor class" => character.equipment_effect_value("armor_class"),
      "Dodge" => "#{character.dodge_bonus}%",
      "Accuracy" => "#{character.accuracy_bonus}%",
      "Crushing" => "#{character.equipment_effect_value("crushing")}%",
      "Fortitude" => "#{character.fortitude_percent}%",
      "Armor pierce" => "#{character.armor_pierce_percent}%"
    }
  end

  def profile_fatigue(character)
    Characters::FatigueService.new(character:).current_percent
  end

  private

  def profile_active_arena_match(character)
    character.arena_participations.includes(arena_match: :arena_room).order(created_at: :desc).detect do |participation|
      match = participation.arena_match
      next false unless match

      match.live? || match.pending? || match.matching? || (match.completed? && participation.metadata.to_h["finished_at"].blank?)
    end&.arena_match
  end
end
