# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe "world/_location_info.html.erb", type: :view do
  let(:zone) { build_stubbed(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:position) { build_stubbed(:character_position, zone:, x: 7, y: 0) }

  it "renders the exact outdoor cell and captured source coordinates" do
    tile = OpenStruct.new(metadata: {"source_coordinates" => [1019, 1025]})

    render partial: "world/location_info", locals: {zone:, position:, tile:}

    expect(rendered).to include("Outpost Surroundings", "[7, 0]", "1019, 1025")
  end

  it "does not invent generic NPC or shop hints for a sparse cell" do
    tile = OpenStruct.new(metadata: {"sparse_default" => true})

    render partial: "world/location_info", locals: {zone:, position:, tile:}

    expect(rendered).not_to include("Hostile NPCs", "Arena and Shop", "🏪", "👤")
  end

  it "handles null tile metadata" do
    tile = OpenStruct.new(metadata: nil)

    expect {
      render partial: "world/location_info", locals: {zone:, position:, tile:}
    }.not_to raise_error
  end
end
