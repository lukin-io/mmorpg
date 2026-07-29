# frozen_string_literal: true

require "rails_helper"

RSpec.describe "management routes", type: :routing do
  it "routes the namespaced management dashboard and CRUD resources" do
    expect(get: "/manage").to route_to(controller: "manage/dashboard", action: "index")
    expect(post: "/manage/world_cells").to route_to(controller: "manage/world_cells", action: "create")
    expect(patch: "/manage/tile_buildings/1").to route_to(controller: "manage/tile_buildings", action: "update", id: "1")
    expect(delete: "/manage/tile_npcs/1").to route_to(controller: "manage/tile_npcs", action: "destroy", id: "1")
    expect(post: "/manage/cities").to route_to(controller: "manage/cities", action: "create")
    expect(patch: "/manage/city_hotspots/1").to route_to(controller: "manage/city_hotspots", action: "update", id: "1")
  end

  it "keeps the audit log read-only" do
    expect(get: "/manage/audit_events").to be_routable
    expect(post: "/manage/audit_events").not_to be_routable
    expect(delete: "/manage/audit_events/1").not_to be_routable
  end
end
