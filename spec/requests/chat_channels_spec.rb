# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ChatChannels", type: :request do
  describe "GET /chat_channels/:id" do
    let(:user) { create(:user) }
    let(:channel) { create(:chat_channel, :global) }

    before { sign_in user, scope: :user }

    it "returns the matching compact frame for the persistent game shell" do
      create(:game_event, recipient: user, body: "Road is clear")

      get chat_channel_path(channel), headers: {"Turbo-Frame" => "chat_messages"}

      expect(response).to have_http_status(:success)
      expect(response.body).to include('<turbo-frame id="chat_messages">')
      expect(response.body).to include("Road is clear")
      expect(response.body).not_to include("chat-channel-page")
    end

    it "interleaves visible gameplay events without exposing another recipient's event" do
      other_user = create(:user)
      world_event = create(:game_event, :world_announcement, body: "The outpost is under attack.", occurred_at: 3.minutes.ago)
      own_event = create(:game_event, :fight_finished, recipient: user, occurred_at: 2.minutes.ago)
      message = create(:chat_message, chat_channel: channel, body: "Ready to defend", created_at: 1.minute.ago)
      create(:game_event, recipient: other_user, body: "Private result")

      get chat_channel_path(channel), headers: {"Turbo-Frame" => "chat_messages"}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("The outpost is under attack.", "Fight finished.")
      expect(response.body).not_to include("Private result", "Ready to defend")
      expect(response.body.index(world_event.body)).to be < response.body.index(own_event.body)
      expect(response.body).to include('id="chat_timeline"')
    end

    it "keeps personal gameplay events in the explicit local channel timeline" do
      character = create(:character, user:)
      create(:character_position, character:)
      get local_chat_path
      local_channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)
      create(:chat_message, chat_channel: local_channel, body: "Local chat row")
      create(:game_event, recipient: user, body: "System row")

      get chat_channel_path(local_channel), headers: {"Turbo-Frame" => "chat_messages"}

      expect(response.body).to include("Local chat row")
      expect(response.body).to include("System row")
    end

    it "renders a stable empty compact state" do
      get chat_channel_path(channel), headers: {"Turbo-Frame" => "chat_messages"}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("No messages yet.")
    end

    it "keeps the full channel page for a normal request" do
      get chat_channel_path(channel)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("chat-channel-page")
    end

    it "returns not found for a missing channel" do
      get chat_channel_path(id: 0), headers: {"Turbo-Frame" => "chat_messages"}

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      sign_out user

      get chat_channel_path(channel), headers: {"Turbo-Frame" => "chat_messages"}

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
