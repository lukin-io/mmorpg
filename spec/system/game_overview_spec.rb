# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Game overview page", type: :system do
  it "shows all sections" do
    driven_by(:rack_test)

    visit game_overview_path

    expect(page).to have_content("Game Overview")
    expect(page).to have_content("Vision & Objectives")
    expect(page).to have_content("Target Audience")
    expect(page).to have_content("Success Metrics")
  end
end
