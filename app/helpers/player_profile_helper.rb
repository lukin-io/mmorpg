# frozen_string_literal: true

module PlayerProfileHelper
  def profile_location(character)
    position = character.position
    return "Unknown" unless position

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
end
