# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World content management", type: :system, js: true do
  let(:admin) { create(:user, :admin) }
  let!(:zone) { create(:zone, :mvp_outdoor_region, name: "Managed Outdoors") }

  before { login_as admin, scope: :user }

  it "keeps the management shell usable at desktop and mobile widths" do
    page.current_window.resize_to(1280, 800)
    visit manage_root_path

    expect(page).to have_css(".nl-manage-dashboard-card", minimum: 7)
    expect(page).to have_link("World Cells")

    click_link "World Cells", match: :first
    click_link "Create world cell"
    select zone.name, from: "Zone"
    fill_in "X", with: 11
    fill_in "Y", with: 12
    fill_in "Metadata and resources (JSON)", with: "{}"
    click_button "Create world cell"

    expect(page).to have_content("World cell created.")
    expect(page).to have_content("Managed Outdoors [11, 12]")

    page.current_window.resize_to(390, 844)
    visit manage_world_cells_path

    metrics = page.evaluate_script(<<~JS)
      ({
        bodyWidth: document.body.scrollWidth,
        viewportWidth: document.documentElement.clientWidth,
        navScrollable: document.querySelector('.nl-manage-nav').scrollWidth >= document.querySelector('.nl-manage-nav').clientWidth,
        tableScrollable: document.querySelector('.nl-manage-table-wrap').scrollWidth > document.querySelector('.nl-manage-table-wrap').clientWidth
      })
    JS
    expect(metrics["bodyWidth"]).to be <= metrics["viewportWidth"]
    expect(metrics["navScrollable"]).to be true
    expect(metrics["tableScrollable"]).to be true
  end

  it "authors per-cell resources and bounded encounter members through guided controls" do
    template = create(:npc_template, npc_key: "managed_system_rat", name: "Managed Rat")
    visit new_manage_world_cell_path
    select zone.name, from: "Zone"
    fill_in "X", with: 11
    fill_in "Y", with: 12
    uncheck "Passable"
    check "Look Around enabled"
    fill_in "Group key", with: "herbs_7"
    fill_in "Resource kind", with: "herbs"
    fill_in "Group label", with: "Herbs group 7"
    click_button "Add resource group"
    expect(page).to have_field("Group key", count: 2)
    all('[data-manage-collection-target="row"]').last.click_button "Remove group"
    click_button "Create world cell"

    expect(page).to have_content("World cell created.")
    expect(page).to have_content("Herbs group 7 (herbs_7; active)")
    expect(MapTileTemplate.find_by!(zone: zone.name, x: 11, y: 12)).not_to be_passable
    click_link "Manage this cell's NPCs"
    expect(page).to have_field("X", with: "11")
    expect(page).to have_field("Y", with: "12")
    select template.name, from: "tile_npc_npc_template_id"
    fill_in "tile_npc_npc_key", with: template.npc_key
    uncheck "Encounter active"
    click_button "Add encounter roster"
    find("summary", text: "New encounter roster").click
    fill_in "Roster key", with: "rats"
    fill_in "Selection weight", with: "2"
    select template.name, from: "roster_0_member_0_npc_key"
    fill_in "roster_0_member_0_level_min", with: "1"
    fill_in "roster_0_member_0_level_max", with: "4"
    fill_in "roster_0_member_0_hp", with: "40"
    page.current_window.resize_to(390, 844)
    expect(page.evaluate_script("document.body.scrollWidth <= document.documentElement.clientWidth")).to be true
    click_button "Create cell NPC"

    expect(page).to have_content("Cell NPC created.")
    npc = TileNpc.find_by!(zone: zone.name, x: 11, y: 12)
    expect(npc).not_to be_active
    expect(npc.encounter_roster_samples.first).to include("key" => "rats", "weight" => 2)
    expect(npc.encounter_roster_samples.first.fetch("members")).to eq([
      {"npc_key" => template.npc_key, "level_min" => 1, "level_max" => 4, "hp" => 40}
    ])
  end
end
