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
end
