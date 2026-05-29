# frozen_string_literal: true

module WorldHelper
  # Get city image path from zone metadata
  #
  # @param zone [Zone] the city zone
  # @return [String] image path or default
  def city_image(zone)
    zone.metadata&.dig("image") || "city_default.jpg"
  end

  # Get city description from zone metadata
  #
  # @param zone [Zone] the city zone
  # @return [String] description text
  def city_description(zone)
    zone.metadata&.dig("description") ||
      "A Neverlands-style city node with source-backed hotspots."
  end

  # Format time remaining in human-readable format
  #
  # @param seconds [Integer] seconds remaining
  # @return [String] formatted time (e.g., "5m 30s", "1h 23m")
  def format_time_remaining(seconds)
    return "now" if seconds.nil? || seconds <= 0

    seconds = seconds.to_i
    if seconds < 60
      "#{seconds}s"
    elsif seconds < 3600
      minutes = seconds / 60
      remaining_secs = seconds % 60
      remaining_secs.positive? ? "#{minutes}m #{remaining_secs}s" : "#{minutes}m"
    else
      hours = seconds / 3600
      remaining_mins = (seconds % 3600) / 60
      remaining_mins.positive? ? "#{hours}h #{remaining_mins}m" : "#{hours}h"
    end
  end

  # Check if position is in a city/town zone
  #
  # @param position [CharacterPosition] the position
  # @return [Boolean] true if in a city
  def in_city?(position)
    zone = position.zone
    zone.city?
  end

  # Format coordinates for display
  #
  # @param x [Integer] x coordinate
  # @param y [Integer] y coordinate
  # @return [String] formatted coordinates
  def format_coordinates(x, y)
    "[#{x}, #{y}]"
  end

  # Get directional arrow for movement
  #
  # @param direction [Symbol] the direction
  # @return [String] arrow character
  def direction_arrow(direction)
    arrows = {
      north: "▲",
      south: "▼",
      east: "▶",
      west: "◀",
      northeast: "↗",
      northwest: "↖",
      southeast: "↘",
      southwest: "↙"
    }
    arrows[direction.to_sym] || "•"
  end
end
