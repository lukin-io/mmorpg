# frozen_string_literal: true

module Game
  module World
    # Source-backed Forpost city graph captured from Neverlands. The Rails MVP
    # uses local outdoor coordinates while retaining observed source coordinates
    # as metadata; no global-region origin is inferred from the capture.
    class CityCatalog
      CITY_KEY = "forpost"
      SCENE_WIDTH = 760
      SCENE_HEIGHT = 255

      NODES = {
        "city2_1" => {
          "zone_name" => "Outpost",
          "title" => "Central Square",
          "links" => {
            "city2_3" => "Residential Quarter",
            "city2_2" => "Trading Quarter"
          },
          "features" => {
            "arena" => {"name" => "Arena", "required_level" => 23}
          }
        },
        "city2_2" => {
          "zone_name" => "Outpost Trading Quarter",
          "title" => "Trading Quarter",
          "links" => {
            "city2_1" => "Central Square",
            "city2_4" => "Industrial Quarter"
          },
          "features" => {
            "shop" => {"name" => "General Shop"},
            "market" => {"name" => "Market"},
            "junk_dealer" => {"name" => "Junk Dealer"},
            "numismatics" => {"name" => "Numismatics Shop"},
            "airship_station" => {"name" => "Oktal Airship Station"}
          }
        },
        "city2_3" => {
          "zone_name" => "Outpost Residential Quarter",
          "title" => "Residential Quarter",
          "links" => {
            "city2_1" => "Central Square",
            "city2_4" => "Industrial Quarter",
            "city2_6" => "Knowledge Quarter"
          },
          "features" => {
            "hospital" => {"name" => "Hospital"}
          }
        },
        "city2_4" => {
          "zone_name" => "Outpost Industrial Quarter",
          "title" => "Industrial Quarter",
          "links" => {
            "city2_2" => "Trading Quarter",
            "city2_3" => "Residential Quarter",
            "city2_5" => "Business Quarter",
            "city2_7" => "Stables"
          },
          "features" => {}
        },
        "city2_5" => {
          "zone_name" => "Outpost Business Quarter",
          "title" => "Business Quarter",
          "links" => {
            "city2_4" => "Industrial Quarter",
            "city2_8" => "Guild Square"
          },
          "features" => {}
        },
        "city2_6" => {
          "zone_name" => "Outpost Knowledge Quarter",
          "title" => "Knowledge Quarter",
          "links" => {
            "city2_3" => "Residential Quarter",
            "city2_9" => "Park",
            "city2_7" => "Stables"
          },
          "features" => {}
        },
        "city2_7" => {
          "zone_name" => "Outpost Stables",
          "title" => "Stables",
          "links" => {
            "city2_4" => "Industrial Quarter",
            "city2_6" => "Knowledge Quarter",
            "city2_8" => "Guild Square"
          },
          "features" => {}
        },
        "city2_8" => {
          "zone_name" => "Outpost Guild Square",
          "title" => "Guild Square",
          "links" => {
            "city2_5" => "Business Quarter",
            "city2_7" => "Stables"
          },
          "features" => {}
        },
        "city2_9" => {
          "zone_name" => "Outpost Park",
          "title" => "Park",
          "links" => {
            "city2_6" => "Knowledge Quarter"
          },
          "features" => {}
        }
      }.freeze

      GATES = {
        "west" => {
          "name" => "West Gate",
          "node_key" => "city2_1",
          "local_coordinates" => [7, 0],
          "source_coordinates" => [1019, 1025],
          "source_map" => "m_1019_1025"
        },
        "south" => {
          "name" => "South Gate",
          "node_key" => "city2_7",
          "local_coordinates" => [10, 3],
          "source_coordinates" => [1022, 1028],
          "source_map" => "m_1022_1028"
        },
        "east" => {
          "name" => "East Gate",
          "node_key" => "city2_8",
          "local_coordinates" => [13, 2],
          "source_coordinates" => [1025, 1027],
          "source_map" => "m_1025_1027"
        }
      }.freeze

      # Presentation geometry follows the live Neverlands city contract: one
      # illustrated 760x255 scene, invisible building regions, and compact
      # route markers around the scene edge. Percentages keep the hit targets
      # aligned when the scene is scaled down on a narrow viewport.
      PRESENTATIONS = {
        "city2_1" => {
          "image_position" => "50% 42%",
          "hotspots" => {
            "arena" => {"polygon" => "26% 0%, 76% 0%, 82% 58%, 73% 72%, 29% 72%, 20% 56%"},
            "west_gate" => {"box" => [0, 18, 17, 72], "marker" => [7, 57], "direction" => "west"},
            "go_city2_3" => {"box" => [18, 77, 29, 23], "marker" => [31, 89], "direction" => "southwest"},
            "go_city2_2" => {"box" => [55, 77, 29, 23], "marker" => [69, 89], "direction" => "southeast"}
          }
        },
        "city2_2" => {
          "image_position" => "76% 76%",
          "hotspots" => {
            "shop" => {"polygon" => "14% 8%, 29% 8%, 29% 57%, 22% 69%, 14% 64%"},
            "market" => {"polygon" => "0% 56%, 54% 56%, 57% 100%, 0% 100%"},
            "junk_dealer" => {"polygon" => "78% 34%, 100% 28%, 100% 92%, 84% 88%"},
            "numismatics" => {"polygon" => "61% 4%, 82% 4%, 80% 48%, 64% 49%"},
            "airship_station" => {"polygon" => "31% 0%, 62% 0%, 62% 47%, 36% 48%"},
            "go_city2_1" => {"box" => [0, 20, 14, 31], "marker" => [5, 35], "direction" => "west"},
            "go_city2_4" => {"box" => [60, 76, 24, 24], "marker" => [72, 89], "direction" => "south"}
          }
        },
        "city2_3" => {
          "image_position" => "18% 70%",
          "hotspots" => {
            "hospital" => {"polygon" => "53% 7%, 94% 7%, 94% 78%, 75% 84%, 55% 67%"},
            "go_city2_1" => {"box" => [0, 21, 14, 31], "marker" => [5, 36], "direction" => "west"},
            "go_city2_4" => {"box" => [86, 22, 14, 31], "marker" => [95, 37], "direction" => "east"},
            "go_city2_6" => {"box" => [46, 76, 28, 24], "marker" => [60, 89], "direction" => "south"}
          }
        },
        "city2_4" => {
          "image_position" => "84% 58%",
          "hotspots" => {
            "go_city2_2" => {"box" => [0, 19, 14, 31], "marker" => [5, 34], "direction" => "west"},
            "go_city2_3" => {"box" => [10, 76, 25, 24], "marker" => [22, 89], "direction" => "southwest"},
            "go_city2_5" => {"box" => [63, 76, 25, 24], "marker" => [76, 89], "direction" => "southeast"},
            "go_city2_7" => {"box" => [86, 19, 14, 31], "marker" => [95, 34], "direction" => "east"}
          }
        },
        "city2_5" => {
          "image_position" => "67% 62%",
          "hotspots" => {
            "go_city2_4" => {"box" => [0, 24, 14, 31], "marker" => [5, 39], "direction" => "west"},
            "go_city2_8" => {"box" => [86, 27, 14, 31], "marker" => [95, 42], "direction" => "east"}
          }
        },
        "city2_6" => {
          "image_position" => "22% 38%",
          "hotspots" => {
            "go_city2_3" => {"box" => [0, 24, 14, 31], "marker" => [5, 39], "direction" => "west"},
            "go_city2_9" => {"box" => [37, 0, 26, 24], "marker" => [50, 10], "direction" => "north"},
            "go_city2_7" => {"box" => [86, 27, 14, 31], "marker" => [95, 42], "direction" => "east"}
          }
        },
        "city2_7" => {
          "image_position" => "88% 86%",
          "hotspots" => {
            "go_city2_4" => {"box" => [0, 14, 14, 31], "marker" => [5, 29], "direction" => "west"},
            "go_city2_6" => {"box" => [22, 0, 26, 24], "marker" => [35, 10], "direction" => "northwest"},
            "go_city2_8" => {"box" => [86, 14, 14, 31], "marker" => [95, 29], "direction" => "east"},
            "south_gate" => {"box" => [37, 76, 26, 24], "marker" => [50, 91], "direction" => "south"}
          }
        },
        "city2_8" => {
          "image_position" => "56% 22%",
          "hotspots" => {
            "go_city2_5" => {"box" => [0, 20, 14, 31], "marker" => [5, 35], "direction" => "west"},
            "go_city2_7" => {"box" => [26, 76, 28, 24], "marker" => [40, 89], "direction" => "southwest"},
            "east_gate" => {"box" => [86, 23, 14, 31], "marker" => [95, 38], "direction" => "east"}
          }
        },
        "city2_9" => {
          "image_position" => "40% 82%",
          "hotspots" => {
            "go_city2_6" => {"box" => [37, 76, 26, 24], "marker" => [50, 89], "direction" => "south"}
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
