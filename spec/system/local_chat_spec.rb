# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Local chat browser buffer", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }

  before { login_as(user, scope: :user) }

  def poll_chat
    page.evaluate_async_script(<<~JS)
      const complete = arguments[0]
      const chat = window.Stimulus.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller~="chat"]'), "chat"
      )
      ;(async () => {
        while (chat.pollRequest) await new Promise(resolve => setTimeout(resolve, 10))
        await chat.pollLocalChat()
        requestAnimationFrame(() => requestAnimationFrame(complete))
      })()
    JS
  end

  it "retains delivered rows through movement, culls the former cell, and deduplicates polling" do
    visit world_path
    expect(page).to have_css("#chat_timeline[data-chat-poll-url-value]")
    find(".nl-chat-input-field").set("Delivered before movement")
    find(".nl-chat-input-field").send_keys(:enter)
    expect(page).to have_css("#chat_timeline article", text: "Delivered before movement", count: 1)
    old_channel = ChatMessage.last.chat_channel

    position.update!(x: 5)
    Chat::LocalContext.new(character:).synchronize!
    visit world_path
    expect(page).to have_css("#chat_timeline article", text: "Delivered before movement", count: 1)

    create(:chat_message, chat_channel: old_channel, body: "Former cell secret")
    channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)
    create(:chat_message, chat_channel: channel, body: "New cell hello")
    poll_chat
    expect(page).to have_css("#chat_timeline article", text: "New cell hello", count: 1)
    expect(page).to have_no_content("Former cell secret")
    poll_chat
    expect(page).to have_css("#chat_timeline article", text: "New cell hello", count: 1)
  end

  it "clears ordinary browser history on a fresh login and restores durable personal events" do
    visit world_path
    expect(page).to have_css("#chat_timeline")
    find(".nl-chat-input-field").set("Previous login row")
    find(".nl-chat-input-field").send_keys(:enter)
    expect(page).to have_content("Previous login row")
    create(:game_event, recipient: user, body: "Retained personal result")

    accept_confirm { find(".nl-close-btn").click }
    expect(page).to have_current_path(new_user_session_path)
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"

    expect(page).to have_css("#chat_timeline", text: "Retained personal result")
    expect(page).to have_no_content("Previous login row")
  end

  it "reports an unimplemented private address without publishing it in ordinary chat" do
    visit world_path
    expect(page).to have_css("#chat_timeline")
    find(".nl-chat-input-field").set("%<Someone> confidential")
    find(".nl-chat-input-field").send_keys(:enter)

    expect(page).to have_css("#flash", text: "Private messaging is not available here.")
    expect(page).to have_no_css("#chat_timeline article", text: "confidential")
    expect(ChatMessage.where(body: "%<Someone> confidential")).not_to exist
  end

  it "clears delivered rows while keeping subsequent chat and event delivery connected" do
    visit world_path
    expect(page).to have_css("#chat_timeline")
    find(".nl-chat-input-field").set("Clear this delivered row")
    find(".nl-chat-input-field").send_keys(:enter)
    expect(page).to have_css("#chat_timeline article", text: "Clear this delivered row")

    click_button "Clear chat"
    expect(page).to have_css("#chat_timeline", visible: :all)
    expect(page).to have_no_css("#chat_timeline article")
    channel = ChatMessage.last.chat_channel
    create(:chat_message, chat_channel: channel, body: "Arrived after clear")
    poll_chat
    expect(page).to have_css("#chat_timeline article", text: "Arrived after clear")
    expect(page).to have_no_content("Clear this delivered row")

    Chat::EventPublisher.new.fight_finished!(recipient: user, experience: 11,
      event_key: "clear-chat:fight:#{user.id}")
    expect(page).to have_css("#chat_timeline article", text: "Combat experience gained: 11")
    visit world_path
    expect(page).to have_css("#chat_timeline article", text: "Arrived after clear")
    expect(page).to have_no_content("Clear this delivered row")
  end

  it "updates the full local-page composer when polling observes movement in another tab" do
    channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)
    visit chat_channel_path(channel)
    expect(page).to have_css(".chat-form[action='#{local_chat_path}']")
    old_key = channel.metadata.fetch("location_key")

    position.update!(x: 5)
    context = Chat::LocalContext.new(character:).synchronize!
    next_channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)
    create(:chat_message, chat_channel: next_channel, body: "Current cell in another tab")
    poll_chat
    expect(page).to have_css("#chat_timeline article", text: "Current cell in another tab")
    expect(find('input[name="context_key"]', visible: false).value).to eq(context.key)
    expect(context.key).not_to eq(old_key)

    fill_in "chat_message_body", with: "Current full-page reply"
    click_button "Send"
    expect(page).to have_css("#chat_timeline article", text: "Current full-page reply")
    expect(ChatMessage.last.chat_channel).to eq(next_channel)
  end

  it "retains its chat frame after a changed-room denial and reads the fresh audience on the next poll" do
    building = create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6)
    visit world_location_path(building.location_key)
    expect(page).to have_css("#chat_timeline[data-chat-poll-url-value]")
    poll_chat
    resume = Game::World::ResumeContext.new(character:)
    changed_room = false
    allow(Chat::Timeline).to receive(:new).and_wrap_original do |original, **arguments|
      timeline = original.call(**arguments)
      unless changed_room
        changed_room = true
        resume.remember_world!
      end
      timeline
    end

    poll_chat

    expect(changed_room).to be(true)
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    expect(page).to have_css("#chat_timeline", count: 1)
    expect(page).to have_no_css("#chat_messages .nl-world-location-scene")
    current_channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)
    create(:chat_message, chat_channel: current_channel, body: "Outside after the room changed")

    poll_chat

    expect(page).to have_css("#chat_timeline article", text: "Outside after the room changed", count: 1)
    expect(find('input[name="context_key"]', visible: false).value)
      .to eq("zone:#{zone.id}:cell:4:6:location:#{building.location_key}:outdoors")
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
  end

  it "shows the new-message indicator on a streamed row while the reader is scrolled up" do
    channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)
    visit chat_channel_path(channel)
    expect(page).to have_css("#chat_timeline")
    30.times { |index| create(:chat_message, chat_channel: channel, body: "Visible history row #{index}") }
    poll_chat
    expect(page).to have_css("#chat_timeline article", count: 30)
    page.execute_script(<<~JS)
      const timeline = document.getElementById("chat_timeline")
      timeline.scrollTop = 0
      timeline.dispatchEvent(new Event("scroll"))
    JS

    Chat::EventPublisher.new.fight_finished!(recipient: user, experience: 12,
      event_key: "scroll-chat:fight:#{user.id}")
    expect(page).to have_css("#chat_timeline article", text: "Combat experience gained: 12")
    expect(page).to have_css(".new-message-indicator.is-visible")
    click_button "New messages"
    expect(page).to have_no_css(".new-message-indicator.is-visible")
  end
end
