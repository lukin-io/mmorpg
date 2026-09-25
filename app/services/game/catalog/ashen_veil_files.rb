# frozen_string_literal: true

module Game
  module Catalog
    # Reads exported Ashen Veil JSON catalogs without pulling Node packages.
    class AshenVeilFiles
      class << self
        def items
          read("ashen_veil_item_catalog.json")
        end

        def enemies
          read("ashen_veil_enemy_catalog.json")
        end

        def dungeons
          read("ashen_veil_dungeon_catalog.json")
        end

        def raids
          read("ashen_veil_raid_catalog.json")
        end

        def progression
          read("ashen_veil_progression.json")
        end

        def read(name)
          path = Rails.root.join("config/gameplay", name)
          return {} unless path.exist?

          JSON.parse(path.read)
        end
      end
    end
  end
end
