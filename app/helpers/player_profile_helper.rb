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
        link_to("in combat", arena_match_path(active_match), class: "nl-profile-fight-link"),
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

  def profile_fatigue(character)
    character.resource_pools.to_h.fetch("fatigue", 0).to_i
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
