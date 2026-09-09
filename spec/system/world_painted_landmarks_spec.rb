# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Painted world landmarks", type: :system, js: true do
  it "removes all legacy village decoration for painted art and shows moved entrances and lobby labels" do
    user = create(:user)
    character = create(:character, user:)
    zone = create(:zone, :mvp_outdoor_region)
    create(:character_position, character:, zone:, x: 5, y: 6)
    [[4, 6], [6, 6], [6, 7], [7, 7]].each do |x, y|
      create(:map_tile_template, zone: zone.name, x:, y:, metadata: {
        "source_map" => "m_#{x + 994}_#{y + 992}",
        "cell_art" => {"key" => "forpost_starter", "column" => x, "row" => y - 2}
      })
    end
    village = create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6,
      building_key: "frontier_village_entrance")
    create(:tile_building, :location_lobby, zone: zone.name, x: 6, y: 7,
      building_key: "managed_mine", name: "Mine")
    exchange_metadata = build(:tile_building, :location_lobby).metadata.deep_dup
    exchange_metadata.fetch("location")["kind"] = "exchange"
    create(:tile_building, :location_lobby, zone: zone.name, x: 7, y: 7,
      building_key: "managed_exchange", name: "Exchange", metadata: exchange_metadata)
    login_as(user, scope: :user)
    page.current_window.resize_to(1500, 1000)

    visit world_path

    expect(page).to have_css("#tile_4_6 .nl-tile-building--painted")
    expect(page).to have_css("#tile_4_6 .nl-entity-label", text: village.name, visible: :all)
    expect(page).to have_no_css("#tile_4_6 .nl-tile-village-hut")
    expect(page.evaluate_script(<<~JS)).to eq(["none", "none", "rgba(0, 0, 0, 0)", "0px", "none"])
      (() => {
        const marker = document.querySelector("#tile_4_6 .nl-tile-building")
        const style = getComputedStyle(marker)
        return [getComputedStyle(marker, "::before").content,
          getComputedStyle(marker, "::after").content,
          style.backgroundColor, style.borderTopWidth, style.boxShadow]
      })()
    JS
    expect(page).to have_css("#tile_6_7 .nl-entity-label:not(.nl-visually-hidden)", text: "Mine")
    expect(page).to have_css("#tile_7_7 .nl-entity-label:not(.nl-visually-hidden)", text: "Exchange")
    expect(page.evaluate_script(<<~JS)).to eq("none")
      getComputedStyle(document.querySelector("#tile_6_7 .nl-tile-building")).pointerEvents
    JS

    village.update!(x: 6)
    visit world_path

    expect(page).to have_no_css("#tile_4_6 .nl-tile-building")
    expect(page).to have_css("#tile_6_6 .nl-tile-village-hut")
    expect(page).to have_no_css("#tile_6_6 .nl-tile-building--painted")
    expect(page.evaluate_script(<<~JS)).not_to eq("none")
      getComputedStyle(document.querySelector("#tile_6_6 .nl-tile-building"), "::before").content
    JS
  end
end
