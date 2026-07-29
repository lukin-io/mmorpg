# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World and City content management", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:outdoor_zone) { create(:zone, :mvp_outdoor_region, name: "Managed Outdoors") }
  let!(:city_zone) { create(:zone, :city_node, name: "Managed City") }

  before { sign_in admin, scope: :user }

  describe "authorization" do
    it "allows only administrators across every management collection" do
      [
        manage_root_path,
        manage_world_cells_path,
        manage_tile_buildings_path,
        manage_npc_templates_path,
        manage_tile_npcs_path,
        manage_cities_path,
        manage_city_hotspots_path,
        manage_audit_events_path
      ].each do |path|
        get path
        expect(response).to have_http_status(:success), path
      end

      sign_out admin
      player = create(:user)
      sign_in player, scope: :user

      get manage_root_path
      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      sign_out admin

      get manage_root_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "world cells and resource actions" do
    let(:metadata) do
      {
        "local_actions" => [
          {"type" => "resource_search", "source_id" => "look", "label" => "Look Around"}
        ]
      }
    end

    it "creates, edits, and deletes the persisted resolver record" do
      expect {
        post manage_world_cells_path, params: {
          map_tile_template: {
            zone: outdoor_zone.name, x: 3, y: 4, terrain_type: "outdoor",
            passable: "1", metadata: JSON.generate(metadata)
          }
        }
      }.to change(MapTileTemplate, :count).by(1)

      cell = MapTileTemplate.last
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(manage_world_cell_path(cell))
      expect(cell.local_action("resource_search")).to include("source_id" => "look")

      patch manage_world_cell_path(cell), params: {
        map_tile_template: {
          zone: outdoor_zone.name, x: 3, y: 4, terrain_type: "outdoor",
          passable: "0", metadata: JSON.generate(metadata)
        }
      }
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(manage_world_cell_path(cell))
      expect(cell.reload).not_to be_passable

      expect { delete manage_world_cell_path(cell) }.to change(MapTileTemplate, :count).by(-1)
      expect(ManagementAuditEvent.where(record_type: "MapTileTemplate").pluck(:action)).to eq(%w[create update destroy])
    end

    it "rejects invalid JSON and preserves state without an audit event" do
      expect {
        post manage_world_cells_path, params: {
          map_tile_template: {
            zone: outdoor_zone.name, x: 3, y: 4, terrain_type: "outdoor",
            passable: "1", metadata: "{invalid"
          }
        }
      }.not_to change { [MapTileTemplate.count, ManagementAuditEvent.count] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("is not valid JSON")
    end
  end

  describe "open-world cell buildings" do
    it "creates, edits, and deletes a city gate through TileBuilding" do
      post manage_tile_buildings_path, params: {
        tile_building: {
          zone: outdoor_zone.name, x: 2, y: 2, building_key: "managed_gate",
          building_type: "city", name: "Managed Gate", destination_zone_id: city_zone.id,
          destination_x: 0, destination_y: 0, required_level: 0, active: "1", metadata: "{}"
        }
      }
      expect(response).to have_http_status(:see_other)
      building = TileBuilding.find_by!(building_key: "managed_gate")

      patch manage_tile_building_path(building), params: {
        tile_building: {
          zone: outdoor_zone.name, x: 2, y: 2, building_key: building.building_key,
          building_type: "city", name: "Renamed Gate", destination_zone_id: city_zone.id,
          destination_x: 0, destination_y: 0, required_level: 0, active: "1", metadata: "{}"
        }
      }
      expect(response).to have_http_status(:see_other)
      expect(building.reload.name).to eq("Renamed Gate")

      expect { delete manage_tile_building_path(building) }.to change(TileBuilding, :count).by(-1)
      expect(ManagementAuditEvent.where(record_type: "TileBuilding").count).to eq(3)
    end
  end

  describe "NPC templates and cell placements" do
    it "manages the catalog and its persisted TileNpc placement" do
      post manage_npc_templates_path, params: {
        npc_template: {
          npc_key: "managed_rat", name: "Managed Rat", npc_role: "hostile", level: 4,
          dialogue: "...", metadata: JSON.generate("health" => 100, "base_damage" => 7)
        }
      }
      expect(response).to have_http_status(:see_other)
      template = NpcTemplate.find_by!(npc_key: "managed_rat")

      post manage_tile_npcs_path, params: {
        tile_npc: {
          zone: outdoor_zone.name, x: 9, y: 8, npc_template_id: template.id,
          npc_key: template.npc_key, npc_role: "hostile", level: 4,
          current_hp: 100, max_hp: 100, metadata: JSON.generate("encounter_count" => 1)
        }
      }
      expect(response).to have_http_status(:see_other)
      placement = TileNpc.find_by!(zone: outdoor_zone.name, x: 9, y: 8)

      patch manage_tile_npc_path(placement), params: {
        tile_npc: {
          zone: outdoor_zone.name, x: 9, y: 8, npc_template_id: template.id,
          npc_key: template.npc_key, npc_role: "hostile", level: 5,
          current_hp: 100, max_hp: 100, metadata: JSON.generate("encounter_count" => 1)
        }
      }
      expect(response).to have_http_status(:see_other)
      expect(placement.reload.level).to eq(5)

      delete manage_tile_npc_path(placement)
      expect(TileNpc.exists?(placement.id)).to be false

      patch manage_npc_template_path(template), params: {
        npc_template: {
          npc_key: template.npc_key, name: "Managed Cave Rat", npc_role: "hostile", level: 4,
          dialogue: "...", metadata: JSON.generate("health" => 100, "base_damage" => 7)
        }
      }
      expect(response).to have_http_status(:see_other)
      expect(template.reload.name).to eq("Managed Cave Rat")

      delete manage_npc_template_path(template)
      expect(NpcTemplate.exists?(template.id)).to be false
      expect(ManagementAuditEvent.where(record_type: "TileNpc").count).to eq(3)
      expect(ManagementAuditEvent.where(record_type: "NpcTemplate").count).to eq(3)
    end

    it "reports a dependency instead of deleting an NPC template still in use" do
      template = create(:npc_template, npc_key: "in_use")
      create(:tile_npc, npc_template: template, npc_key: template.npc_key)

      expect { delete manage_npc_template_path(template) }.not_to change(NpcTemplate, :count)

      expect(response).to redirect_to(manage_npc_template_path(template))
      expect(ManagementAuditEvent.where(record_type: "NpcTemplate", action: "destroy")).to be_empty
    end
  end

  describe "city nodes and actions" do
    it "creates, edits, and deletes DB-backed city presentation and hotspot data" do
      city_metadata = {
        "city_key" => "managed",
        "city_node_key" => "square",
        "title" => "Managed Square",
        "city_presentation" => {"image_offset" => [0, 0], "focus" => [625, 300], "landmarks" => {}}
      }
      post manage_cities_path, params: {
        zone: {name: "Managed Square Zone", width: 10, height: 10, metadata: JSON.generate(city_metadata)}
      }
      expect(response).to have_http_status(:see_other)
      city = Zone.find_by!(name: "Managed Square Zone")
      expect(city).to be_city

      post manage_city_hotspots_path, params: {
        city_hotspot: {
          zone_id: city.id, key: "shop", name: "Shop", hotspot_type: "building",
          position_x: 15, position_y: 25, width: 200, height: 100,
          action_type: "open_feature", action_params: JSON.generate("feature" => "shop"),
          required_level: 0, z_index: 1, active: "1"
        }
      }
      expect(response).to have_http_status(:see_other)
      hotspot = CityHotspot.find_by!(zone: city, key: "shop")
      expect(hotspot.presentation_box).to eq([15, 25, 200, 100])

      patch manage_city_hotspot_path(hotspot), params: {
        city_hotspot: {
          zone_id: city.id, key: hotspot.key, name: "Supply Shop", hotspot_type: "building",
          position_x: 15, position_y: 25, width: 240, height: 100,
          action_type: "open_feature", action_params: JSON.generate("feature" => "shop"),
          required_level: 0, z_index: 1, active: "1"
        }
      }
      expect(response).to have_http_status(:see_other)
      expect(hotspot.reload).to have_attributes(name: "Supply Shop", width: 240)

      delete manage_city_hotspot_path(hotspot)
      expect(CityHotspot.exists?(hotspot.id)).to be false

      city_metadata["title"] = "Renamed Square"
      patch manage_city_path(city), params: {
        zone: {name: city.name, width: 10, height: 10, metadata: JSON.generate(city_metadata)}
      }
      expect(response).to have_http_status(:see_other)
      expect(city.reload.display_name).to eq("Renamed Square")

      delete manage_city_path(city)
      expect(Zone.exists?(city.id)).to be false
      expect(ManagementAuditEvent.where(record_type: "CityHotspot").count).to eq(3)
      expect(ManagementAuditEvent.where(record_type: "Zone", record_id: city.id).count).to eq(3)
    end
  end

  describe "audit log" do
    it "renders immutable mutation details" do
      event = create(:management_audit_event, actor: admin)

      get manage_audit_events_path
      expect(response.body).to include("Management Audit Log", event.record_label)

      get manage_audit_event_path(event)
      expect(response.body).to include("Audit Event ##{event.id}", "passable")
    end
  end
end
