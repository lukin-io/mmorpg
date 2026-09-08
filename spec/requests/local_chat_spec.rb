# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Current-location ordinary chat", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }
  let(:headers) { {"Accept" => "application/json"} }

  before do
    sign_in user, scope: :user
    get local_chat_path
  end

  def channel_for(recipient = user)
    Chat::ChannelRouter.new(user: recipient).resolve(scope: :local)
  end

  def current_key
    Chat::LocalContext.new(character: character.reload).key
  end

  it "posts only to the server's current cell and returns the sender's row without a shared broadcast" do
    expect do
      post local_chat_path, params: {context_key: current_key, chat_message: {body: "Cell hello"}},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}
    end.to change(ChatMessage, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('action="append"', 'target="chat_timeline"', "Cell hello")
    expect(ChatMessage.last.chat_channel).to have_attributes(channel_type: "local", metadata: {"location_key" => current_key})
  end

  it "lets two users in the same cell reuse the channel and each post" do
    post local_chat_path, params: {context_key: current_key, chat_message: {body: "First player"}}, headers: headers
    first_channel = ChatMessage.last.chat_channel
    other = create(:character)
    create(:character_position, character: other, zone:, x: 4, y: 6)
    sign_out user
    sign_in other.user, scope: :user
    get local_chat_path
    key = Chat::LocalContext.new(character: other.reload).key

    expect do
      post local_chat_path, params: {context_key: key, chat_message: {body: "Second player"}}, headers: headers
    end.to change(ChatMessage, :count).by(1)
    expect(response).to have_http_status(:created)
    expect(ChatMessage.last.chat_channel).to eq(first_channel)
  end

  it "polls only the exact cell and keeps personal/world events in the initial shell" do
    channel = channel_for
    travel 1.second
    create(:chat_message, chat_channel: channel, sender: user, body: "Current cell")
    other = create(:character)
    create(:character_position, character: other, zone:, x: 5, y: 6)
    create(:chat_message, chat_channel: channel_for(other.user), body: "Adjacent secret")
    create(:game_event, recipient: user, body: "Own durable result")
    create(:game_event, recipient: create(:user), body: "Foreign result")
    create(:game_event, :world_announcement, body: "World notice")

    get local_chat_path

    expect(response.body).to include("Current cell", "Own durable result", "World notice")
    expect(response.body).not_to include("Adjacent secret", "Foreign result")
    expect(response.body).not_to include(Turbo::StreamsChannel.signed_stream_name(channel))

    get local_chat_path(poll: 1)
    expect(response.body).to include("Current cell")
    expect(response.body).not_to include("Own durable result", "World notice", "turbo-cable-stream-source")
  end

  it "rejects remote and unbound legacy channels for reads and writes" do
    remote = create(:chat_channel, channel_type: :local, metadata: {"location_key" => "remote-cell"})
    legacy = create(:chat_channel, channel_type: :local, metadata: {"local_key" => "client-chosen"})
    [remote, legacy].each do |channel|
      create(:chat_message, chat_channel: channel, body: "Hidden channel")
      get chat_channel_path(channel)
      expect(response).to have_http_status(:not_found)
      expect(Nokogiri::HTML(response.body).css("article[data-message-id]")).to be_empty

      expect do
        post chat_channel_chat_messages_path(channel), params: {chat_message: {body: "Invalid"}}, headers:
      end.not_to change(ChatMessage, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "rejects an old cell form after movement and excludes messages from before the new visit" do
    original = channel_for
    original_key = current_key
    create(:chat_message, chat_channel: original, body: "Before departure")
    position.update!(x: 5)
    Chat::LocalContext.new(character:).synchronize!

    expect do
      post local_chat_path, params: {context_key: original_key, chat_message: {body: "Stale form"}}, headers:
    end.not_to change(ChatMessage, :count)
    expect(response).to have_http_status(:forbidden)

    travel 1.second
    position.update!(x: 4)
    Chat::LocalContext.new(character:).synchronize!
    get local_chat_path(poll: 1)
    expect(response.body).not_to include("Before departure")
  end

  it "ignores submitted room and coordinate keys when choosing the read audience" do
    remote = create(:chat_channel, channel_type: :local, metadata: {"location_key" => "remote-cell"})
    create(:chat_message, chat_channel: remote, body: "Remote message")

    get local_chat_path(poll: 1), params: {local_key: "remote-cell", channel_id: remote.id, x: 999, room: "shop"}

    expect(response.body).not_to include("Remote message")
    expect(response.body).to include(current_key)
  end

  it "rejects ordinary global posts and hides legacy global player history" do
    global = create(:chat_channel, :global)
    create(:chat_message, chat_channel: global, body: "Legacy worldwide message")

    expect do
      post chat_channel_chat_messages_path(global), params: {chat_message: {body: "Global post"}}, headers:
    end.not_to change(ChatMessage, :count)
    expect(response).to have_http_status(:forbidden)

    get chat_channel_path(global)
    expect(response.body).not_to include("Legacy worldwide message")
  end

  it "excludes earlier-login ordinary rows while keeping durable personal events" do
    channel = channel_for
    create(:chat_message, chat_channel: channel, body: "Earlier login")
    create(:game_event, recipient: user, body: "Persisted personal event")
    session = user.user_sessions.sole
    travel 1.second
    session.update!(signed_in_at: Time.current)

    get local_chat_path

    expect(response.body).not_to include("Earlier login")
    expect(response.body).to include("Persisted personal event")
  end

  it "denies a closed session even if its authenticated request was already started" do
    user.user_sessions.sole.close!

    get local_chat_path(poll: 1), headers: headers

    expect(response).to have_http_status(:unauthorized)

    expect do
      post local_chat_path, params: {context_key: current_key, chat_message: {body: "Late post"}}, headers: headers
    end.not_to change(ChatMessage, :count)
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a room change during an HTML chat read without redirecting back into the former room" do
    building = create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6)
    resume = Game::World::ResumeContext.new(character:)
    [
      {"Accept" => "text/html", "X-Requested-With" => "XMLHttpRequest"},
      {"Accept" => "text/html", "Turbo-Frame" => "chat_messages"}
    ].each do |read_headers|
      resume.remember_world_location!(key: building.location_key)
      # The channel has been selected, but Leave wins before the timeline's
      # locked authorization check. No sleeps or relaxed authorization needed.
      allow(Chat::Timeline).to receive(:new).and_wrap_original do |original, **arguments|
        timeline = original.call(**arguments)
        resume.remember_world!
        timeline
      end

      get local_chat_path(poll: 1), headers: read_headers.merge("Referer" => world_location_url(building.location_key))

      expect(response).to have_http_status(:forbidden)
      expect(response.headers["Location"]).to be_nil
      expect(response.body).to be_empty
      expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
      expect(position.reload).to have_attributes(zone:, x: 4, y: 6)

      allow(Chat::Timeline).to receive(:new).and_call_original
      get local_chat_path(poll: 1), headers: read_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("zone:#{zone.id}:cell:4:6:location:#{building.location_key}:outdoors")
      expect(response.body).not_to include("location:#{building.location_key}:village")
    end
  end

  it "requires an authenticated verified player with a position" do
    sign_out user
    get local_chat_path(poll: 1)
    expect(response).to redirect_to(new_user_session_path)
  end
end
