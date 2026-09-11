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

  it "renders the complete Central Square illustration and matching highlight dimensions" do
    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop, to_business],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to have_css(".nl-city-viewport[data-controller='nl-scene-size nl-city-map']")
    expect(rendered).to have_css(".nl-city-scene[data-nl-scene-size-target='canvas']")
    expect(rendered).to have_css("img.nl-city-scene-image[src='#{view.asset_path('city/central-square.png')}']")
    scene = Nokogiri::HTML.fragment(rendered).at_css(".nl-city-scene")
    expect(scene["style"]).to include(
      "--nl-city-image-url: url(#{view.asset_path('city/central-square.png').to_json})",
      "--nl-city-image-width: 1250px", "--nl-city-image-height: 600px",
      "--nl-city-image-x: 0px", "--nl-city-image-y: 0px"
    )
    expect(rendered).to have_css(".nl-city-viewport > .nl-city-tooltip[data-nl-city-map-target='tooltip']", visible: :all)
  end

  {
    "forpost1" => ["residential-quarter.png", "main", {
      "clan_hall" => "Clan Hall", "post" => "Post Office", "city_hall" => "City Hall"
    }],
    "forpost2" => ["knowledge-quarter.png", "forpost1", {
      "magic_school" => "Magic School", "library" => "Library",
      "general_school" => "General School", "military_school" => "Military School"
    }],
    "forpost3" => ["business-quarter.png", "main", {
      "auction" => "Auction", "souvenir_shop" => "Souvenir Shop", "dealer_house" => "Dealer House",
      "obelisk" => "Obelisk", "temple" => "Temple of Ilana", "bank" => "Bank"
    }],
    "forpost4" => ["law-quarter.png", "forpost1", {
      "law_abode" => "Law Abode", "prison" => "Prison", "gallows" => "Gallows"
    }]
  }.each do |node_key, (image_name, destination_key, landmarks)|
    it "renders #{node_key}'s own illustration, landmark silhouettes and named route" do
      node = Game::World::CityCatalog.node(node_key)
      business.update!(metadata: {"city_key" => "forpost", "city_node_key" => node_key,
        "title" => node.fetch("title"), "city_presentation" => Game::World::CityCatalog.presentation(node_key)})
      destination_name = Game::World::CityCatalog.node(destination_key).fetch("title")
      destination = create(:zone, :city, name: "Destination #{node_key}",
        metadata: {"city_key" => "forpost", "city_node_key" => destination_key, "title" => destination_name})
      route = create(:city_hotspot, :district, zone: business, destination_zone: destination,
        key: "go_#{destination_key}", name: destination_name)

      render partial: "world/city_view", locals: {
        zone: business, hotspots: [route],
        offers_by_hotspot_id: {route.id => OpenStruct.new(action_key: "return-action-key")}
      }

      expect(rendered).to have_css("img.nl-city-scene-image[src='#{view.asset_path("city/#{image_name}")}']", count: 1)
      expect(rendered).to have_css(".nl-city-viewport[data-controller='nl-scene-size nl-city-map']")
      expect(rendered).not_to have_css(".nl-city-scene--pending, .nl-city-pending-notice")
      expect(rendered).to have_css("[data-landmark-key]", count: landmarks.length)
      landmarks.each do |key, name|
        expect(rendered).to have_css("[data-landmark-key='#{key}'][aria-label='#{name}'][tabindex='0'][style*='--nl-city-hotspot-clip: polygon(']", visible: :all)
      end
      expect(rendered).not_to have_css("form [data-landmark-key]")
      expect(rendered).to have_button(destination_name, count: 1)
      expect(rendered).to have_css("input[name='action_key'][value='return-action-key']", visible: :all)
      expect(rendered).to have_css("button[data-hotspot-key='go_#{destination_key}'] img.nl-city-route-marker[alt=''][aria-hidden='true']")
    end
  end

  it "does not guess artwork for an older persisted crop without an explicit asset" do
    zone.update!(metadata: zone.metadata.merge("city_presentation" => {
      "image_offset" => [-143, -212], "landmarks" => {}
    }))

    render partial: "world/city_view", locals: {zone:, hotspots: []}

    expect(rendered).to have_css(".nl-city-scene--pending")
    expect(rendered).to have_content("This quarter is not ready yet.")
    expect(rendered).not_to have_css(".nl-city-scene-image, .nl-city-landmarks, .nl-city-tooltip")
    expect(rendered).not_to have_css("[data-controller~='nl-scene-size'], [data-controller~='nl-city-map']")
  end

  it "renders pixel building regions, route arrows, and server capability fields" do
    render partial: "world/city_view", locals: {
      zone:,
      hotspots: [shop, to_business],
      offers_by_hotspot_id: offers
    }

    expect(rendered).to have_button("Shop")
    expect(rendered).to have_css(".nl-city-scene button[data-hotspot-key='shop']")
    expect(rendered).to have_css(".nl-city-viewport > .nl-city-routes button[data-hotspot-key='go_forpost3']", count: 1)
    expect(rendered).not_to have_css(".nl-city-scene button[data-hotspot-key='go_forpost3']")
    expect(rendered).to have_css(".nl-city-hotspot[data-hotspot-key='shop'][style*='--nl-city-hotspot-clip: polygon(']", visible: :all)
    expect(rendered).to have_css(".nl-city-hotspot[data-hotspot-key='go_forpost3']", visible: :all)
    expect(rendered).to have_css("img.nl-city-route-marker[data-direction='southwest'][src='#{view.asset_path('city/route-arrow.png')}'][alt=''][aria-hidden='true'][draggable='false']")
    expect(rendered).to have_css("input[name='action_key'][value='shop-action-key']", visible: :all)
  end

  it "keeps the generated route decoration on an unavailable region without a submit action" do
    render partial: "world/city_view", locals: {
      zone:, hotspots: [to_business], offers_by_hotspot_id: {}
    }

    expect(rendered).not_to have_button("Business Quarter")
    expect(rendered).to have_css("[data-hotspot-key='go_forpost3'][role='img'][aria-label='Business Quarter'] img.nl-city-route-marker[alt=''][aria-hidden='true']")
    expect(rendered).not_to have_css("form")
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
    expect(rendered).to have_css("[data-hotspot-key='custom_route'][style*='--nl-city-route-width: 180px']", visible: :all)
  end

  it "prefers managed zone and hotspot presentation records over catalog fallbacks" do
    zone.update!(
      metadata: zone.metadata.merge(
        "city_presentation" => {
          "image_asset" => "arena.png",
          "image_size" => [768, 512],
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

    expect(rendered).to have_css("img.nl-city-scene-image[src='#{view.asset_path('arena.png')}']")
    scene = Nokogiri::HTML.fragment(rendered).at_css(".nl-city-scene")
    expect(scene["style"]).to include(
      "--nl-city-image-url: url(#{view.asset_path('arena.png').to_json})",
      "--nl-city-image-width: 768px", "--nl-city-image-height: 512px",
      "--nl-city-image-x: -10px", "--nl-city-image-y: -20px"
    )
    expect(rendered).to have_css("[data-hotspot-key='shop'][style*='width: 210px']", visible: :all)
    expect(rendered).to have_css("[data-landmark-key='managed_landmark'][aria-label='Managed Landmark']", visible: :all)
  end
end
