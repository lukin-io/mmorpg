# frozen_string_literal: true

require "rails_helper"

RSpec.describe "city building routes", type: :routing do
  it "routes an allowlisted building key to the read-only city surface" do
    expect(get: "/city/buildings/market").to route_to(
      controller: "city_buildings",
      action: "show",
      building_key: "market"
    )
  end

  it "does not expose an economic mutation route for captured read-only services" do
    expect(post: "/city/buildings/market").not_to be_routable
  end
end
