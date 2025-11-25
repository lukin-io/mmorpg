require "rails_helper"

RSpec.describe Moderation::ChatPipeline do
  let(:user) { create(:user) }
  let(:channel) { create(:chat_channel, channel_type: :global) }
  let(:moderation_handler) { instance_double(Chat::Moderation::CommandHandler) }
  let(:spam_throttler) { instance_double(Chat::SpamThrottler, check!: true) }

  before do
    allow(ChatModerationAction).to receive(:muting?).and_return(false)
    allow(moderation_handler).to receive(:call).and_return(
      Chat::Moderation::CommandHandler::Result.new(handled?: false)
    )
  end

  it "returns a non-command result when checks pass" do
    result = described_class.new(
      user: user,
      channel: channel,
      input: "hello world",
      moderation_handler: moderation_handler,
      spam_throttler: spam_throttler
    ).call

    expect(result.command_executed?).to be(false)
  end

  it "raises when the whisper target blocks messages" do
    target = create(:user, chat_privacy: :nobody)
    whisper_channel = create(
      :chat_channel,
      channel_type: :whisper,
      metadata: {"participant_ids" => [user.id, target.id]}
    )

    expect do
      described_class.new(
        user: user,
        channel: whisper_channel,
        input: "psst",
        moderation_handler: moderation_handler,
        spam_throttler: spam_throttler
      ).call
    end.to raise_error(Chat::Errors::PrivacyBlockedError)
  end
end
