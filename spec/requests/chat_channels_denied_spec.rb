# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Chat channels", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Chat Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when opening a missing chat channel" do
    get chat_channel_path(999_999_999)

    expect(response).to redirect_to(world_path(chat_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-chat-denied="1"')
    expect(response.body).to include('data-chat-recovery="world"')
  end
end
