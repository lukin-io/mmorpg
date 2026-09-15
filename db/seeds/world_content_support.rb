# frozen_string_literal: true

module Seeds
  # Shared source declarations and capability cleanup for authored seed content.
  # Attribute builders perform no writes. Changed targets cancel live offers;
  # callers supply the transaction surrounding each content record write.
  module WorldContentSupport
    module_function

    def city_zones
      Zone.where(location_type: "city").select do |zone|
        zone.metadata.to_h["city_key"] == Game::World::CityCatalog::CITY_KEY
      end
    end

    def zone_metadata_for(name)
      city_node = Game::World::CityCatalog::NODES.values.find { |node| node["zone_name"] == name }
      if city_node
        city_node_key = Game::World::CityCatalog::NODES.key(city_node)
        city_presentation = Game::World::CityCatalog.presentation(city_node_key)
        return {
          "city_key" => Game::World::CityCatalog::CITY_KEY,
          "city_node_key" => city_node_key,
          "title" => city_node["title"],
          "description" => "Forpost — #{city_node['title']}",
          "city_presentation" => city_presentation
        }
      end

      case name
      when "Outpost Surroundings"
        {
          "source_map" => "m_1001_999"
        }
      else
        {}
      end
    end

    # Shared source-backed declarations used by normal seeds and the bounded
    # gate repair. These methods only build attributes; callers own writes.
    def gate_building_attributes(gate_key:, gate:, city_zone:, outdoors:)
      x, y = gate.fetch("local_coordinates")
      {
        zone: outdoors.name, x:, y:,
        building_key: (gate_key == "west" ? "outpost_gate" : "outpost_#{gate_key}_gate"),
        building_type: "city", name: gate.fetch("name"), destination_zone: city_zone,
        destination_x: 0, destination_y: 0, icon: nil, required_level: 0,
        metadata: {
          "description" => "Enter Forpost through the #{gate.fetch('name')}.",
          "presence_label" => gate.fetch("presence_label"),
          "source_map" => gate.fetch("source_map"),
          "source_coordinates" => gate.fetch("source_coordinates"),
          "source_gate" => gate_key, "city_node_key" => gate.fetch("node_key")
        }
      }
    end

    def gate_hotspot_definition(gate_key:, gate:, city_zone:, outdoors:)
      x, y = gate.fetch("local_coordinates")
      {
        zone: city_zone, key: "#{gate_key}_gate", name: gate.fetch("name"),
        hotspot_type: "exit", action_type: "enter_zone", destination_zone: outdoors,
        action_params: {"destination_x" => x, "destination_y" => y,
                        "source_coordinates" => gate.fetch("source_coordinates")},
        presentation: Game::World::CityCatalog.hotspot_presentation(gate.fetch("node_key"), "#{gate_key}_gate") || {},
        required_level: 0
      }
    end

    def outdoor_route_tiles(outdoor_zone_name)
      outdoor_tiles = []
      Game::World::CityCatalog::GATES.each_value do |gate|
        local_x, local_y = gate["local_coordinates"]
        outdoor_tiles << {
          zone: outdoor_zone_name,
          x: local_x,
          y: local_y,
          terrain_type: "outdoor",
          passable: true,
          metadata: {
            "city_gate" => gate["name"],
            "source_map" => gate["source_map"],
            "source_coordinates" => gate["source_coordinates"],
            "cell_art" => {
              "key" => "forpost_terrain",
              "column" => local_x.modulo(10),
              "row" => local_y.modulo(10)
            }
          }
        }
      end
      outdoor_tiles << {
        zone: outdoor_zone_name,
        x: 7,
        y: 7,
        terrain_type: "outdoor",
        passable: true,
        metadata: {
          "source_map" => "m_1001_999",
          "source_coordinates" => [1001, 999],
          "cell_art" => {
            "key" => "forpost_terrain",
            "column" => 7,
            "row" => 7
          },
          "local_actions" => [
            {
              "type" => "resource_search",
              "source_id" => "look",
              "label" => "Look Around",
              "description" => "Search this cell for herbs or local resources."
            }
          ]
        }
      }
      outdoor_tiles << {
        zone: outdoor_zone_name,
        x: 4,
        y: 6,
        terrain_type: "outdoor",
        passable: true,
        metadata: {
          "source_map" => "m_998_998",
          "source_coordinates" => [998, 998],
          "cell_art" => {
            "key" => "forpost_terrain",
            "column" => 4,
            "row" => 6
          }
        }
      }

      # Source [999,999] already carries the village-area label, but its cell
      # has no entrance. The authored TileBuilding at [4,6] alone supplies Enter.
      outdoor_tiles << {
        zone: outdoor_zone_name, x: 5, y: 7, terrain_type: "outdoor", passable: true,
        metadata: {
          "source_map" => "m_999_999", "source_coordinates" => [999, 999],
          "source_observation" => "2026-09-09_starter_routes",
          "presence_label" => "Frontier Village"
        }
      }

      # September 8 live pond: source [1007,1002], reached from the eastern
      # gate. Drinking is captured; fishing's successful profession loop remains
      # deferred. Cell art and action eligibility are independent authored data.
      outdoor_tiles << {
        zone: outdoor_zone_name,
        x: 13,
        y: 10,
        terrain_type: "outdoor",
        passable: true,
        metadata: {
          "source_map" => "m_1007_1002",
          "source_coordinates" => [1007, 1002],
          "source_observation" => "2026-09-08_cell_content_and_world_rules",
          "presence_label" => "Outpost Surroundings, Pond",
          "cell_art" => {"key" => "forpost_pond", "column" => 2, "row" => 2},
          "local_actions" => [
            {"type" => "resource_search", "source_id" => "look", "label" => "Look Around", "active" => true,
             "result_message" => "Nothing found."},
            {"type" => "drinking", "source_id" => "dri", "label" => "Drink", "active" => true},
            {"type" => "fishing", "source_id" => "fis", "label" => "Fish", "active" => true}
          ]
        }
      }

      # Live eastern intermediate [1006,1002]: Look is available here, with
      # the captured 28-second empty-vegetation result; water actions are absent.
      outdoor_tiles << {
        zone: outdoor_zone_name, x: 12, y: 10, terrain_type: "outdoor", passable: true,
        metadata: {
          "source_map" => "m_1006_1002",
          "source_coordinates" => [1006, 1002],
          "source_observation" => "2026-09-09_starter_routes",
          "local_actions" => [{"type" => "resource_search", "source_id" => "look", "label" => "Look Around"}]
        }
      }
      outdoor_tiles
    end

    def starter_cell_attributes(cell, metadata:)
      merged = cell.metadata.merge(metadata).merge(
        "source_map" => cell.metadata.fetch("source_map"),
        "source_coordinates" => cell.metadata.fetch("source_coordinates")
      )
      merged["resource_groups"] ||= cell.metadata.dig("atlas", "herb_groups").map do |group|
        {"key" => "herbs_#{group}", "kind" => "herbs", "label" => "Herb group #{group}", "active" => true}
      end
      {terrain_type: "outdoor", passable: cell.passable, metadata: merged}
    end

    def starter_cell_art(x, y)
      if x == 20 && (6..7).cover?(y)
        return {"key" => "forpost_ogre_habitat", "column" => 0, "row" => y - 6}
      end

      {"key" => "forpost_starter", "column" => x, "row" => y - 2}
    end

    def retire_action_targets(target_type, targets)
      return unless defined?(WorldActionOffer)

      target_offers = WorldActionOffer.where(target_type:, target_id: targets.select(:id))
      live_statuses = WorldActionOffer.statuses.values_at("offered", "accepted")
      target_offers.where(status: live_statuses).update_all(
        status: WorldActionOffer.statuses.fetch("cancelled"),
        error_message: "Authored world content was updated.",
        updated_at: Time.current
      )
      target_offers.update_all(target_type: nil, target_id: nil, updated_at: Time.current)
    end

    def cancel_changed_action_offers(target)
      return unless defined?(WorldActionOffer) && target.persisted? && target.has_changes_to_save?

      WorldActionOffer.where(
        target:,
        status: WorldActionOffer.statuses.values_at("offered", "accepted")
      ).update_all(
        status: WorldActionOffer.statuses.fetch("cancelled"),
        error_message: "Authored world content was updated.",
        updated_at: Time.current
      )
    end
  end
end
