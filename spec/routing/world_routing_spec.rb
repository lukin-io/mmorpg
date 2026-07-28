# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world routes", type: :routing do
  it "routes the source-backed current-cell local action endpoint" do
    expect(post: "/world/perform_local_action").to route_to(
      controller: "world",
      action: "perform_local_action"
    )
  end

  it "routes allowlisted world-location scenes and their offered features" do
    expect(get: "/world/locations/frontier_village").to route_to(
      controller: "world_locations",
      action: "show",
      key: "frontier_village"
    )
    expect(post: "/world/locations/frontier_village/features").to route_to(
      controller: "world_locations",
      action: "open_feature",
      key: "frontier_village"
    )
  end

  it "does not route the removed arbitrary location-name entry endpoint" do
    expect(post: "/world/enter").not_to be_routable
  end

  it "does not route the removed generic city-exit endpoint" do
    expect(post: "/world/exit_location").not_to be_routable
  end

  it "does not expose a manual wilderness-NPC attack endpoint" do
    expect(post: "/fight/npc").not_to be_routable
  end
end
