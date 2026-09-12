# frozen_string_literal: true

module PlayerProfileHelper
  def profile_location(character)
    position = character.position
    return "Unknown" unless position

    zone_label = position.zone.display_name
    location_label = Game::World::Presence.new(character:, position:).label
    active_match = profile_active_arena_match(character)
    first_line = [ERB::Util.html_escape(zone_label)]
    if active_match
      location_label = active_match.arena_room.name if active_match.arena_room
      first_line.concat([
        " [ ",
        link_to("in combat", public_fight_log_path(active_match), class: "nl-profile-fight-link"),
        " ]"
      ])
    end

    lines = [safe_join(first_line)]
    lines << ERB::Util.html_escape(location_label) unless location_label == zone_label
    safe_join(lines, tag.br)
  end

  def profile_skill_level(character, key)
    character.passive_skill_level(key).to_s.rjust(3, "0")
  end

  def profile_attack_cost(character)
    Arena::CombatProfile.for_character(character).fetch("physical_attack_cost_seed")
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

  # Derived combat values shown as chips under the profile parameter column.
  #
  # Row set and order follow the live profile capture recorded in
  # `doc/design/reference/neverlands_live_style_system.md`. Fatigue is rendered
  # separately because the source gives it its own chip color. The source
  # "artifact coefficient" row is intentionally absent: its mechanic is not
  # captured, so it is not invented here.
  def profile_combat_stats(character)
    {
      "AP per strike" => profile_attack_cost(character),
      "Armor class" => character.armor_class,
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
