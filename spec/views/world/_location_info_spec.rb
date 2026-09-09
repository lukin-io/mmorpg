# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_location_info.html.erb", type: :view do
  let(:zone) { build_stubbed(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:position) { build_stubbed(:character_position, zone:, x: 7, y: 0) }

  it "renders the local outdoor cell without exposing source coordinates" do
    render partial: "world/location_info", locals: {position:, location_label: "Outpost, East Gate"}

    expect(rendered).to include("Outpost, East Gate", "[7, 0]")
    expect(rendered).not_to include("1019, 1025")
  end

  it "does not invent generic NPC or shop hints for a sparse cell" do
    render partial: "world/location_info", locals: {position:, location_label: zone.display_name}

    expect(rendered).not_to include("Hostile NPCs", "Arena and Shop", "🏪", "👤")
  end

  it "escapes the authored location label" do
    render partial: "world/location_info", locals: {position:, location_label: "Pond <script>alert(1)</script>"}

    expect(rendered).to include("Pond &lt;script&gt;alert(1)&lt;/script&gt;")
    expect(rendered).not_to have_css("script")
  end
end
