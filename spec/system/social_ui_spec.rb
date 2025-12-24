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

    it "creates a friend request from the friends UI" do
      create(:character, user: user)
      create(:character, user: other_user)

      visit friendships_path

      select other_user.email, from: "Select player"
      click_button "Send Request"

      expect(page).to have_content("Friend request sent")
      expect(page).to have_content(other_user.email)
    end

    it "sends in-game mail from the mailbox UI" do
      create(:character, user: user)
      create(:character, user: other_user)

      visit new_mail_message_path

      fill_in "Recipient Email", with: other_user.email
      fill_in "Subject", with: "Hello"
      fill_in "Body", with: "Meet me in town."
      click_button "Send"

      expect(page).to have_content("Mail sent")
      expect(page).to have_content("Hello")
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

    it "reports a chat message and shows the moderation panel" do
      channel = create(:chat_channel, name: "Global")
      message = create(:chat_message, chat_channel: channel, sender: other_user, body: "Buy gold", filtered_body: "Buy gold")

      visit chat_channel_path(channel)

      expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(message)}")

      find("##{ActionView::RecordIdentifier.dom_id(message)}").hover
      accept_confirm { find("form .chat-msg-report-btn", match: :first).click }

      expect(page).to have_css("#flash", text: "Report submitted")

      visit moderation_panel_path
      expect(page).to have_content("Moderation Panel")
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

    it "shows a validation error when mailing an unknown recipient" do
      create(:character, user: user)

      visit new_mail_message_path

      fill_in "Recipient Email", with: "missing@elselands.test"
      fill_in "Subject", with: "Hello"
      fill_in "Body", with: "Test"
      click_button "Send"

      expect(page).to have_content("Recipient not found")
    end
  end

  describe "null/edge cases" do
    it "shows an empty state for a new mailbox" do
      create(:character, user: user)

      visit mail_messages_path

      expect(page).to have_content("No messages yet")
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

    it "blocks non-moderators from the chat reports index" do
      visit chat_reports_path

      expect(page).to have_css("#flash", text: "not authorized")
    end
  end
end
