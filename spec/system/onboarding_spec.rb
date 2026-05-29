# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Onboarding", type: :system do
  describe "success cases" do
    it "signs in via Devise UI and lands on the world page" do
      user = create(:user, password: "Password123!", password_confirmation: "Password123!")
      zone = create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 10, height: 10)
      character = create(:character, user: user)
      create(:character_position, character: character, zone: zone, x: 5, y: 5)

      visit new_user_session_path

      fill_in "Email", with: user.email
      fill_in "Password", with: "Password123!"
      click_button "Enter"

      expect(page).to have_css(".nl-map-container")
      expect(page).to have_content("Outpost Surroundings")
    end
  end

  describe "failure cases" do
    it "shows an error for invalid credentials" do
      user = create(:user, password: "Password123!", password_confirmation: "Password123!")

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "WrongPassword!"
      click_button "Enter"

      expect(page).to have_content(I18n.t("devise.failure.invalid", authentication_keys: "email"))
    end
  end

  describe "null/edge cases" do
    it "boots a character with no position from the configured starter spawn" do
      user = create(:user, password: "Password123!", password_confirmation: "Password123!")
      zone = create(:zone, name: "Outpost", location_type: "city", width: 10, height: 10)
      create(:spawn_point, zone: zone, x: 5, y: 5, default_entry: true)
      create(:character, user: user)

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "Password123!"
      click_button "Enter"

      expect(page).to have_css(".city-view-container")
      expect(page).to have_content("Outpost")
    end

    it "shows validation errors when signing up with blank fields" do
      visit new_user_registration_path

      fill_in "Email", with: ""
      fill_in "Password", with: ""
      fill_in "Password confirmation", with: ""
      click_button "Create Account"

      expect(page).to have_content("can't be blank")
    end
  end

  describe "authorization cases" do
    it "blocks login for unconfirmed users" do
      user = create(:user, confirmed_at: nil, password: "Password123!", password_confirmation: "Password123!")

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "Password123!"
      click_button "Enter"

      expect(page).to have_content("confirm your email address")
    end
  end
end
