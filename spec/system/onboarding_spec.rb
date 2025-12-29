# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Onboarding", type: :system, js: true do
  describe "success cases" do
    it "signs in via Devise UI and lands on the world page" do
      user = create(:user, password: "Password123!", password_confirmation: "Password123!")
      zone = create(:zone, name: "Starter Plains", biome: "plains", width: 10, height: 10)
      character = create(:character, user: user)
      create(:character_position, character: character, zone: zone, x: 5, y: 5)

      visit new_user_session_path

      fill_in "Email", with: user.email
      fill_in "Password", with: "Password123!"
      click_button "Enter the Realm"

      expect(page).to have_css(".nl-map-container")
      expect(page).to have_content("Starter Plains")
    end
  end

  describe "failure cases" do
    it "shows an error for invalid credentials" do
      user = create(:user, password: "Password123!", password_confirmation: "Password123!")

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "WrongPassword!"
      click_button "Enter the Realm"

      expect(page).to have_content("Invalid Email or password")
    end
  end

  describe "null/edge cases" do
    it "boots a character with no position by auto-creating a starter position" do
      user = create(:user, password: "Password123!", password_confirmation: "Password123!")
      create(:zone, name: "Starter Plains", biome: "plains", width: 10, height: 10)
      create(:character, user: user)

      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "Password123!"
      click_button "Enter the Realm"

      expect(page).to have_css(".nl-map-container")
      expect(page).to have_content("Starter Plains")
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
      click_button "Enter the Realm"

      expect(page).to have_content("confirm your email address")
    end
  end
end
