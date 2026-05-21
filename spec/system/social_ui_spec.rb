# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Social UI", type: :system, js: true do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe "success cases" do
    it "sends a chat message and renders it via Turbo Streams" do
      channel = create(:chat_channel, name: "Global")

      visit chat_channel_path(channel)

      fill_in "chat_message_body", with: "Hello from system spec"
      click_button "Send"
      expect(page).to have_content("Hello from system spec")
    end

    it "adds a player to the ignore list" do
      create(:character, user: user)
      create(:character, user: other_user)

      visit ignore_list_entries_path

      select other_user.profile_name, from: "Player"
      fill_in "Notes", with: "Spamming"
      click_button "Add to ignore list"

      expect(page).to have_content("Player ignored")
      expect(page).to have_content(other_user.profile_name)
    end
  end

  describe "failure cases" do
    it "shows a validation error for blank chat messages" do
      channel = create(:chat_channel, name: "Global")

      visit chat_channel_path(channel)

      fill_in "chat_message_body", with: ""
      click_button "Send"

      expect(page).to have_content("message cannot be blank")
    end
  end

  describe "authorization cases" do
    it "blocks unverified users from social features" do
      logout(:user)
      unverified = create(:user, confirmed_at: nil)
      login_as(unverified, scope: :user)

      visit chat_channels_path

      expect(page).to have_css("#flash", text: "confirm your email address")
    end
  end
end
