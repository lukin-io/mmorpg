require "rails_helper"

RSpec.describe "ChatMessages", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let!(:position) { create(:character_position, character:) }
  let(:channel) { Chat::ChannelRouter.new(user:).resolve(scope: :local) }

  describe "POST /chat_channels/:chat_channel_id/chat_messages" do
    it "creates a chat message" do
      sign_in user, scope: :user

      expect do
        post chat_channel_chat_messages_path(channel), params: {chat_message: {body: "Hello"}}
      end.to change(ChatMessage, :count).by(1)

      expect(response).to have_http_status(:found)
    end

    it "rejects blank messages" do
      sign_in user, scope: :user

      post chat_channel_chat_messages_path(channel), params: {chat_message: {body: ""}}

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "recovers when posting to a missing chat channel" do
      sign_in user, scope: :user

      post chat_channel_chat_messages_path(999_999_999), params: {chat_message: {body: "stale"}}

      expect(response).to redirect_to(world_path(chat_denied: 1))
      follow_redirect!
      expect(response.body).to include('data-chat-denied="1"')
      expect(response.body).to include('data-chat-recovery="world"')
    end
  end
end
