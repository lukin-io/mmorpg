# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_city_hotspot.html.erb", type: :view do
  let(:zone) { create(:zone, name: "Outpost", location_type: "city") }
  let(:character) { create(:character, level: 10) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_character).and_return(character)
    end
  end

  it "renders source-image hotspot coordinates as responsive percentages" do
    hotspot = create(:city_hotspot,
      :arena,
      zone:,
      position_x: 455,
      position_y: 55,
      width: 790,
      height: 500,
      required_level: 1)

    render partial: "world/city_hotspot", locals: {hotspot:}

    expect(rendered).to have_css(".city-hitbox[data-hotspot-key='arena']")
    expect(rendered).to include("left:29.6224%;top:5.3711%;width:51.4323%;height:48.8281%;")
    expect(rendered).to have_css("button[aria-label='Войти: Arena']", visible: :all)
  end
end
