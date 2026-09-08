# frozen_string_literal: true

module AirshipsHelper
  def airship_terrain_style(map)
    origin = map.tiles.flatten.first
    left = 350 - (map.center_x - origin.x + 0.5) * 100
    top = 150 - (map.center_y - origin.y + 0.5) * 100
    "transform: translate(#{left}px, #{top}px)"
  end

  def airship_timer(seconds)
    remaining = [seconds.to_i, 0].max
    format("%02d:%02d:%02d", remaining / 3600, remaining / 60 % 60, remaining % 60)
  end

  def airship_tile_style(tile)
    return "background-color: #d9d6cc;" if tile.terrain_type == "void"

    art = tile.art
    if art
      "background-image: url('#{image_path(art.asset)}'); background-position: #{art.background_x}px #{art.background_y}px; background-size: #{art.sheet_width}px #{art.sheet_height}px;"
    else
      "background-image: url('#{image_path('world/forpost-terrain.png')}'); background-position: #{-tile.x.to_i.modulo(10) * 100}px #{-tile.y.to_i.modulo(10) * 100}px; background-size: 1000px 1000px;"
    end
  end
end
