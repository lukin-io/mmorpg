# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_city_view.html.erb", type: :view do
  let(:character) { create(:character, level: 24) }
  let(:zone) do
    create(
      :zone,
      :city,
      name: "Test Trading Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "city2_2", "title" => "Trading Quarter"}
    )
  end
  let(:central) { create(:zone, :city_node, name: "Test Central Square") }
  let(:shop) { create(:city_hotspot, :shop, zone:, key: "shop", name: "General Shop") }
  let(:to_central) do
    create(
      :city_hotspot,
      :district,
      zone:,
      destination_zone: central,
      key: "go_city2_1",
      name: "Central Square"
    )
  end
  let(:offers) do
    {
      shop.id => OpenStruct.new(action_key: "shop-action-key"),
      to_central.id => OpenStruct.new(action_key: "central-action-key")
    }
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_character).and_return(character)
    end
  end

  it "renders the retained illustration as a 760 by 255 city navigation scene" do
    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop, to_central],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to have_css(".nl-city-scene[data-controller='nl-city-map']")
    expect(rendered).to have_css("img.nl-city-scene-image[src*='city']")
    expect(rendered).to have_css(".nl-city-tooltip[data-nl-city-map-target='tooltip']", visible: :all)
  end

  it "renders polygon building regions and compact route markers from server offers" do
    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop, to_central],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to have_button("General Shop")
    expect(rendered).to have_css(".nl-city-hotspot--polygon[data-hotspot-key='shop']", visible: :all)
    expect(rendered).to have_css(".nl-city-hotspot[data-hotspot-key='go_city2_1']", visible: :all)
    expect(rendered).to have_css(".nl-city-route-marker[data-direction='west']")
    expect(rendered).to have_css("input[name='action_key'][value='shop-action-key']", visible: :all)
  end

  it "keeps a level-blocked hotspot discoverable without rendering a submit action" do
    arena_zone = create(
      :zone,
      :city,
      name: "Test Central",
      metadata: {"city_key" => "forpost", "city_node_key" => "city2_1", "title" => "Central Square"}
    )
    arena = create(:city_hotspot, :arena, zone: arena_zone, required_level: 50)

    render partial: "world/city_view", locals: {
      zone: arena_zone,
      hotspots: [arena],
      offers_by_hotspot_id: {}
    }

    expect(rendered).not_to have_button("Arena")
    expect(rendered).to have_css(
      ".nl-city-hotspot--unavailable[aria-label*='Requires level 50']",
      visible: :all
    )
  end

  it "uses a bounded route fallback for an unknown custom hotspot" do
    custom = create(
      :city_hotspot,
      :district,
      zone:,
      destination_zone: central,
      key: "custom_route",
      name: "Custom Route"
    )

    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [custom],
      offers_by_hotspot_id: {custom.id => OpenStruct.new(action_key: "custom-key")}
    }

    expect(rendered).to have_button("Custom Route")
    expect(rendered).to have_css("[data-hotspot-key='custom_route'][style*='width: 16%']", visible: :all)
  end
end
