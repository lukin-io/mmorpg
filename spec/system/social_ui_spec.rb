# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Social UI", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }

  before do
    login_as(user, scope: :user)
  end

  describe "success cases" do
    it "sends an authorized local chat message and renders its Turbo response" do
      channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)

      visit chat_channel_path(channel)

      fill_in "chat_message_body", with: "Hello from system spec"
      click_button "Send"
      expect(page).to have_content("Hello from system spec")
      expect(ChatMessage.last).to have_attributes(chat_channel: channel, sender: user)
    end

    it "streams a personal game event into the same chat timeline" do
      channel = create(:chat_channel, :global, name: "Global")

      visit chat_channel_path(channel)
      expect(page).to have_css("#chat_timeline", count: 1)

      Chat::EventPublisher.new.fight_finished!(
        recipient: user,
        experience: 10,
        event_key: "system-spec:fight-finished:#{user.id}"
      )

      expect(page).to have_css("#chat_timeline .game-event--fight-finished", text: "Combat experience gained: 10")
      expect(page).to have_no_content("No messages yet.")
    end
  end

  describe "failure cases" do
    it "shows a validation error for blank chat messages" do
      channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)

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
      channel = create(:chat_channel, name: "Global")
      login_as(unverified, scope: :user)

      visit chat_channel_path(channel)

      expect(page).to have_css("#flash", text: "confirm your email address")
    end
  end
end
