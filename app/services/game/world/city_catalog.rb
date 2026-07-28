# frozen_string_literal: true

module Game
  module World
    # Authored Forpost city graph and presentation metadata. Geometry is stored
    # in native scene pixels so the illustration, hover regions, and route
    # arrows retain their desktop proportions while narrow clients pan it.
    class CityCatalog
      CITY_KEY = "forpost"
      STARTER_NODE_KEY = "main"
      SCENE_WIDTH = 1250
      SCENE_HEIGHT = 600
      IMAGE_WIDTH = 1536
      IMAGE_HEIGHT = 1024

      NODES = {
        "main" => {
          "zone_name" => "Outpost",
          "title" => "Central Square",
          "links" => {
            "forpost3" => "Business Quarter",
            "forpost1" => "Residential Quarter"
          },
          "features" => {
            "arena" => {"name" => "Arena", "required_level" => 0},
            "shop" => {"name" => "Shop"},
            "hospital" => {"name" => "Hospital"}
          }
        },
        "forpost1" => {
          "zone_name" => "Outpost Residential Quarter",
          "title" => "Residential Quarter",
          "links" => {
            "main" => "Central Square",
            "forpost2" => "Knowledge Quarter",
            "forpost4" => "Law Quarter"
          },
          "features" => {
            "airship_station" => {"name" => "Airship Station"},
            "market" => {"name" => "Market"}
          }
        },
        "forpost2" => {
          "zone_name" => "Outpost Knowledge Quarter",
          "title" => "Knowledge Quarter",
          "links" => {"forpost1" => "Residential Quarter"},
          "features" => {}
        },
        "forpost3" => {
          "zone_name" => "Outpost Business Quarter",
          "title" => "Business Quarter",
          "links" => {"main" => "Central Square"},
          "features" => {}
        },
        "forpost4" => {
          "zone_name" => "Outpost Law Quarter",
          "title" => "Law Quarter",
          "links" => {"forpost1" => "Residential Quarter"},
          "features" => {}
        }
      }.freeze

      # The exact outdoor handoff has been verified for the Central Square
      # exit. The second illustrated exit in the Law Quarter remains a
      # presentation-only landmark until its outdoor destination is captured.
      GATES = {
        "west" => {
          "name" => "City Exit",
          "node_key" => "main",
          "local_coordinates" => [7, 0],
          "source_coordinates" => [1019, 1025],
          "source_map" => "m_1019_1025"
        }
      }.freeze

      PRESENTATIONS = {
        "main" => {
          "image_offset" => [-143, -212],
          "focus" => [625, 300],
          "hotspots" => {
            "arena" => {"box" => [374, 0, 570, 336]},
            "shop" => {"box" => [96, 303, 320, 182]},
            "hospital" => {"box" => [807, 282, 441, 266]},
            "west_gate" => {"box" => [0, 25, 168, 307]},
            "go_forpost3" => {"box" => [308, 501, 76, 99], "direction" => "southwest"},
            "go_forpost1" => {"box" => [900, 496, 68, 104], "direction" => "southeast"}
          },
          "landmarks" => {
            "tavern" => {"name" => "Tavern", "box" => [154, 167, 192, 117]},
            "workshop" => {"name" => "Workshop", "box" => [982, 182, 245, 112]},
            "guard_tower" => {"name" => "Guard Tower", "box" => [240, 20, 79, 158]}
          }
        },
        "forpost1" => {
          "image_offset" => [0, -280],
          "focus" => [625, 330],
          "hotspots" => {
            "airship_station" => {"box" => [794, 125, 262, 354]},
            "market" => {"box" => [278, 338, 368, 184]},
            "go_main" => {"box" => [39, 534, 90, 66], "direction" => "west"},
            "go_forpost2" => {"box" => [780, 496, 68, 104], "direction" => "southeast"},
            "go_forpost4" => {"box" => [1105, 448, 90, 67], "direction" => "east"}
          },
          "landmarks" => {
            "clan_hall" => {"name" => "Clan Hall", "box" => [514, 48, 336, 246]},
            "post" => {"name" => "Post", "box" => [123, 236, 146, 196]},
            "city_hall" => {"name" => "City Hall", "box" => [184, 0, 305, 333]}
          }
        },
        "forpost2" => {
          "image_offset" => [-120, 0],
          "focus" => [625, 300],
          "hotspots" => {
            "go_forpost1" => {"box" => [245, 30, 89, 84], "direction" => "northwest"}
          },
          "landmarks" => {
            "magic_school" => {"name" => "Magic School", "box" => [202, 224, 209, 344]},
            "library" => {"name" => "Library", "box" => [156, 120, 355, 230]},
            "general_school" => {"name" => "General School", "box" => [660, 82, 362, 189]},
            "military_school" => {"name" => "Military School", "box" => [842, 283, 315, 250]}
          }
        },
        "forpost3" => {
          "image_offset" => [-286, -250],
          "focus" => [625, 320],
          "hotspots" => {
            "go_main" => {"box" => [650, 17, 57, 104], "direction" => "north"}
          },
          "landmarks" => {
            "auction" => {"name" => "Auction", "box" => [244, 311, 666, 289]},
            "souvenir_shop" => {"name" => "Souvenir Shop", "box" => [231, 233, 210, 207]},
            "dealer_house" => {"name" => "Dealer House", "box" => [73, 0, 310, 219]},
            "obelisk" => {"name" => "Obelisk", "box" => [602, 52, 63, 207]},
            "temple" => {"name" => "Temple", "box" => [812, 156, 435, 444]},
            "bank" => {"name" => "Bank", "box" => [871, 17, 237, 215]}
          }
        },
        "forpost4" => {
          "image_offset" => [-286, -20],
          "focus" => [625, 300],
          "hotspots" => {
            "go_forpost1" => {"box" => [84, 297, 76, 100], "direction" => "west"}
          },
          "landmarks" => {
            "law_abode" => {"name" => "Law Abode", "box" => [55, 0, 370, 332]},
            "city_exit" => {"name" => "City Exit", "box" => [46, 343, 371, 257]},
            "prison" => {"name" => "Prison", "box" => [578, 81, 379, 419]},
            "gallows" => {"name" => "Gallows", "box" => [472, 154, 176, 99]}
          }
        }
      }.freeze

      class << self
        def node(node_key)
          NODES[node_key.to_s]
        end

        def presentation(node_key)
          PRESENTATIONS[node_key.to_s]
        end

        def hotspot_presentation(node_key, hotspot_key)
          presentation(node_key)&.dig("hotspots", hotspot_key.to_s)
        end
      end
    end
  end
end
