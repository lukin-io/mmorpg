# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Perk Allocation", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, perk_points: 1) }

  before do
    login_as(user, scope: :user)
    allow_any_instance_of(CharactersController).to receive(:current_character).and_return(character)
    visit perks_character_path(character)
  end

  it "previews, undoes, and saves a captured binary perk" do
    within(".nl-perk-row[data-perk='more_strength']") do
      expect(page).to have_content("No")
      click_button "+"
      expect(page).to have_css(".nl-perk-state--pending", text: "Yes")
      click_button "-"
      expect(page).to have_content("No")
      click_button "+"
    end

    expect(page).to have_css("[data-perk-allocation-target='freePoints']", text: "0")
    click_button "Save"

    expect(page).to have_content("Perks saved")
    expect(character.reload).to be_owns_perk(:more_strength)
    expect(page).not_to have_button("+")
  end
end
