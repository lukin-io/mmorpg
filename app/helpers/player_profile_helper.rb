# frozen_string_literal: true

module PlayerProfileHelper
  def profile_location(character)
    position = character.position
    return I18n.t("game.profile.unknown_location") unless position

    zone_label = position.zone.display_name
    location_label = Game::World::Presence.new(character:, position:).label
    active_match = profile_active_arena_match(character)
    first_line = [ERB::Util.html_escape(zone_label)]
    if active_match
      location_label = active_match.arena_room.name if active_match.arena_room
      first_line.concat([
        " [ ",
        link_to(I18n.t("game.profile.in_combat"), public_fight_log_path(active_match), class: "nl-profile-fight-link"),
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

  # Derived combat values shown as chips under the profile parameter column.
  #
  # Row set and order follow the live profile capture recorded in
  # `doc/design/reference/neverlands_live_style_system.md`. Fatigue is rendered
  # separately because the source gives it its own chip color. The source
  # "artifact coefficient" row is intentionally absent: its mechanic is not
  # captured, so it is not invented here.
  def profile_combat_stats(character)
    {
      I18n.t("game.sheet.ap_per_strike") => profile_attack_cost,
      I18n.t("game.sheet.attack_power") => character.attack_power,
      I18n.t("game.sheet.defense") => character.defense,
      I18n.t("game.sheet.accuracy") => "#{character.accuracy_bonus}%",
      I18n.t("game.sheet.dodge") => "#{character.dodge_bonus}%",
      I18n.t("game.sheet.dexterity") => character.stats.get(:dexterity).to_i,
      I18n.t("game.sheet.agility") => character.agility.to_i,
      I18n.t("game.sheet.luck") => character.stats.get(:luck).to_i,
      I18n.t("game.sheet.magic_power") => character.magic_power,
      I18n.t("game.sheet.armor_class") => character.equipment_effect_value("armor_class")
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

      match.live? || match.pending? || match.matching?
    end&.arena_match
  end
end
