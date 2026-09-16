# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_equipment_paperdoll.html.erb", type: :view do
  it "renders the original player portrait inside the shared equipment rails" do
    character = build_stubbed(:character, name: "PortraitPlayer")
    render partial: "shared/equipment_paperdoll", locals: {character:, equipment: {}, interactive: false}

    portrait = Nokogiri::HTML.fragment(rendered).at_css(".nl-doll-portrait img")
    expect(portrait["src"]).to eq(view.image_path("avatars/adventurer.png"))
    expect(portrait["alt"]).to eq(character.name)
    expect(rendered).to have_css(".nl-doll-slot--off_hand")
  end
end
