# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_city_view.html.erb", type: :view do
  let(:character) { create(:character, level: 16) }
  let(:zone) do
    create(
      :zone,
      :city,
      name: "Test Central Square",
      metadata: {"city_key" => "forpost", "city_node_key" => "main", "title" => "Central Square"}
    )
  end
  let(:business) do
    create(
      :zone,
      :city,
      name: "Test Business Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "forpost3", "title" => "Business Quarter"}
    )
  end
  let(:shop) { create(:city_hotspot, :shop, zone:, key: "shop", name: "Shop") }
  let(:to_business) do
    create(
      :city_hotspot,
      :district,
      zone:,
      destination_zone: business,
      key: "go_forpost3",
      name: "Business Quarter"
    )
  end
  let(:offers) do
    {
      shop.id => OpenStruct.new(action_key: "shop-action-key"),
      to_business.id => OpenStruct.new(action_key: "business-action-key")
    }
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_character).and_return(character)
    end
  end

  it "renders the project illustration in a native 1250 by 600 pannable city scene" do
    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop, to_business],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to have_css(".nl-city-viewport[data-controller='nl-city-map']")
    expect(rendered).to have_css(".nl-city-scene[data-nl-city-map-target='scene']")
    expect(rendered).to have_css("img.nl-city-scene-image[src*='city']")
    expect(rendered).to include("--nl-city-image-x: -143px", "--nl-city-image-y: -212px")
    expect(rendered).to have_css(".nl-city-tooltip[data-nl-city-map-target='tooltip']", visible: :all)
  end

  it "renders pixel building regions, route arrows, and server capability fields" do
    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop, to_business],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to have_button("Shop")
    expect(rendered).to have_css(".nl-city-hotspot[data-hotspot-key='shop'][style*='width: 320px']", visible: :all)
    expect(rendered).to have_css(".nl-city-hotspot[data-hotspot-key='go_forpost3']", visible: :all)
    expect(rendered).to have_css(".nl-city-route-marker[data-direction='southwest']", text: ">")
    expect(rendered).to have_css("input[name='action_key'][value='shop-action-key']", visible: :all)
  end

  it "renders presentation-only landmarks as focusable tooltip regions" do
    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to have_css(".nl-city-hotspot--landmark[data-landmark-key='tavern'][tabindex='0']", visible: :all)
    expect(rendered).to have_css(".nl-city-hotspot--landmark[aria-label='Workshop']", visible: :all)
    expect(rendered).not_to have_css("form [data-landmark-key]")
  end

  it "keeps a blocked hotspot discoverable without rendering a submit action" do
    arena = create(:city_hotspot, :arena, zone:, required_level: 50)

    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [arena],
      offers_by_hotspot_id: {}
    }

    expect(rendered).not_to have_button("Arena")
    expect(rendered).to have_css(
      ".nl-city-hotspot--unavailable[aria-label*='Requires level 50']",
      visible: :all
    )
  end

  it "uses a bounded native-pixel fallback for an unknown custom route" do
    custom = create(
      :city_hotspot,
      :district,
      zone:,
      destination_zone: business,
      key: "custom_route",
      name: "Custom Route"
    )

    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [custom],
      offers_by_hotspot_id: {custom.id => OpenStruct.new(action_key: "custom-key")}
    }

    expect(rendered).to have_button("Custom Route")
    expect(rendered).to have_css("[data-hotspot-key='custom_route'][style*='width: 180px']", visible: :all)
  end

  it "prefers managed zone and hotspot presentation records over catalog fallbacks" do
    zone.update!(
      metadata: zone.metadata.merge(
        "city_presentation" => {
          "image_offset" => [-10, -20],
          "focus" => [300, 250],
          "landmarks" => {
            "managed_landmark" => {"name" => "Managed Landmark", "box" => [4, 5, 60, 70]}
          }
        }
      )
    )
    shop.update!(position_x: 10, position_y: 20, width: 210, height: 110)

    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to include("--nl-city-image-x: -10px", "--nl-city-image-y: -20px")
    expect(rendered).to have_css("[data-hotspot-key='shop'][style*='width: 210px']", visible: :all)
    expect(rendered).to have_css("[data-landmark-key='managed_landmark'][aria-label='Managed Landmark']", visible: :all)
  end
end
