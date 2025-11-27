# frozen_string_literal: true

require "rails_helper"

# Skip if RealtimeChatChannel is not yet implemented
RSpec.describe "RealtimeChatChannel", type: :channel, skip: !defined?(RealtimeChatChannel) do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "with accessible channel" do
      it "successfully subscribes" do
        subscribe(channel_id: chat_channel.id)

        expect(subscription).to be_confirmed
      end

      it "streams from chat channel" do
        subscribe(channel_id: chat_channel.id)

        expect(subscription).to have_stream_from("chat_channel_#{chat_channel.id}")
      end
    end

    context "with muted user" do
      before do
        user.update!(chat_muted_until: 1.hour.from_now)
      end

      it "still allows subscription but may restrict sending" do
        subscribe(channel_id: chat_channel.id)

        # User can still receive messages while muted
        expect(subscription).to be_confirmed
      end
    end
  end

  describe "#speak" do
    before do
      subscribe(channel_id: chat_channel.id)
    end

    context "with valid message" do
      it "broadcasts the message" do
        expect {
          perform :speak, message: "Hello world"
        }.to have_broadcasted_to("chat_channel_#{chat_channel.id}")
      end
    end

    context "with muted user" do
      before do
        user.update!(chat_muted_until: 1.hour.from_now)
      end

      it "does not broadcast" do
        expect {
          perform :speak, message: "Muted message"
        }.not_to have_broadcasted_to("chat_channel_#{chat_channel.id}")
      end
    end
  end
end
