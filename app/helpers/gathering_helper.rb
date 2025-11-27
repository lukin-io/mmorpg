# frozen_string_literal: true

module GatheringHelper
  def resource_icon(resource_key)
    case resource_key.to_s
    when /herb/, /plant/, /flower/
      "🌿"
    when /ore/, /metal/, /iron/, /copper/, /gold/
      "⛏️"
    when /wood/, /log/, /timber/
      "🪵"
    when /fish/, /catch/
      "🐟"
    when /gem/, /crystal/
      "💎"
    when /hide/, /leather/, /fur/
      "🦌"
    when /cloth/, /fabric/, /silk/
      "🧵"
    else
      "✨"
    end
  end

  def time_until_available(respawn_at)
    return "Available" unless respawn_at.present?
    return "Available" if respawn_at <= Time.current

    seconds = (respawn_at - Time.current).to_i
    if seconds < 60
      "#{seconds}s"
    elsif seconds < 3600
      "#{seconds / 60}m #{seconds % 60}s"
    else
      "#{seconds / 3600}h #{(seconds % 3600) / 60}m"
    end
  end

  def rarity_color_class(rarity)
    case rarity.to_s
    when "common" then "rarity-common"
    when "uncommon" then "rarity-uncommon"
    when "rare" then "rarity-rare"
    when "epic" then "rarity-epic"
    when "legendary" then "rarity-legendary"
    else "rarity-common"
    end
  end
end
