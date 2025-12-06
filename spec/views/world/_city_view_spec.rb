# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_city_view.html.erb", type: :view do
  let(:zone) do
    create(:zone,
      name: "Capital City",
      biome: "city",
      width: 15,
      height: 15,
      metadata: {
        "description" => "A magnificent capital full of wonder.",
        "warning" => "Beware of pickpockets!",
        "quest_hint" => "Talk to the guard captain for your first quest."
      })
  end
  let(:character) { create(:character) }
  let(:position) { create(:character_position, character: character, zone: zone, x: 7, y: 7) }

  before do
    assign(:zone, zone)
    assign(:position, position)

    without_partial_double_verification do
      allow(view).to receive(:city_buildings).and_return([])
      allow(view).to receive(:current_character).and_return(character)
      allow(view).to receive(:building_icon).and_return("🏛️")
    end
  end

  it "renders the city view container" do
    render partial: "world/city_view", locals: {zone: zone, position: position}

    expect(rendered).to have_css(".nl-city-view")
  end

  it "renders the city image container" do
    render partial: "world/city_view", locals: {zone: zone, position: position}

    expect(rendered).to have_css(".nl-city-image-container")
  end

  it "includes city placeholder for missing images" do
    render partial: "world/city_view", locals: {zone: zone, position: position}

    expect(rendered).to have_css(".nl-city-placeholder")
    expect(rendered).to have_css(".nl-city-placeholder-name")
    expect(rendered).to include("Capital City")
  end

  it "renders the city description section" do
    render partial: "world/city_view", locals: {zone: zone, position: position}

    expect(rendered).to have_css(".nl-city-description")
    expect(rendered).to include("magnificent capital")
  end

  it "displays warning text when present" do
    render partial: "world/city_view", locals: {zone: zone, position: position}

    expect(rendered).to have_css(".nl-warning")
    expect(rendered).to include("Beware of pickpockets")
  end

  it "displays quest hint as clickable highlight when present" do
    render partial: "world/city_view", locals: {zone: zone, position: position}

    expect(rendered).to have_css(".nl-highlight")
    expect(rendered).to include("Talk to the guard captain")
  end

  it "includes stimulus controller data attributes" do
    render partial: "world/city_view", locals: {zone: zone, position: position}

    expect(rendered).to have_css("[data-controller='city']")
    expect(rendered).to have_css("[data-city-zone-id-value]")
  end

  context "with buildings" do
    let(:buildings) do
      [
        {
          id: 1,
          name: "Blacksmith",
          type: "shop",
          key: "blacksmith",
          description: "Craft and repair weapons",
          grid_x: 2,
          grid_y: 3,
          npcs: ["Master Smith"]
        },
        {
          id: 2,
          name: "Inn",
          type: "inn",
          key: "inn",
          description: "Rest and recover",
          grid_x: 4,
          grid_y: 5,
          npcs: ["Innkeeper"]
        }
      ]
    end

    before do
      without_partial_double_verification do
        allow(view).to receive(:city_buildings).and_return(buildings)
      end
    end

    it "renders building elements" do
      render partial: "world/city_view", locals: {zone: zone, position: position}

      expect(rendered).to have_css(".city-building", count: 2)
    end

    it "displays building names" do
      render partial: "world/city_view", locals: {zone: zone, position: position}

      expect(rendered).to have_css(".city-building-name")
      expect(rendered).to include("Blacksmith")
      expect(rendered).to include("Inn")
    end

    it "includes building data attributes" do
      render partial: "world/city_view", locals: {zone: zone, position: position}

      expect(rendered).to have_css("[data-building-id='1']")
      expect(rendered).to have_css("[data-building-name='Blacksmith']")
      expect(rendered).to have_css("[data-building-type='shop']")
    end
  end

  context "without metadata" do
    let(:zone_no_metadata) do
      create(:zone, name: "Empty City", biome: "city", metadata: nil)
    end

    it "renders default description" do
      render partial: "world/city_view", locals: {zone: zone_no_metadata, position: position}

      expect(rendered).to have_css(".nl-city-description")
      expect(rendered).to include("bustling city") # default text
    end

    it "does not render warning section" do
      render partial: "world/city_view", locals: {zone: zone_no_metadata, position: position}

      expect(rendered).not_to have_css(".nl-warning")
    end
  end
end

