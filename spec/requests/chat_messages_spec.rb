require "rails_helper"

RSpec.describe "ChatMessages", type: :request do
  describe "POST /chat_channels/:chat_channel_id/chat_messages" do
    it "creates a chat message" do
      user = create(:user)
      channel = create(:chat_channel)

      sign_in user, scope: :user

      expect do
        post chat_channel_chat_messages_path(channel), params: {chat_message: {body: "Hello"}}
      end.to change(ChatMessage, :count).by(1)

      expect(response).to have_http_status(:found)
    end

    it "rejects muted players" do
      user = create(:user)
      channel = create(:chat_channel)
      create(:chat_moderation_action, target_user: user, actor: create(:user), action_type: :mute_global)

      sign_in user, scope: :user

      post chat_channel_chat_messages_path(channel), params: {chat_message: {body: "Hello"}}

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
