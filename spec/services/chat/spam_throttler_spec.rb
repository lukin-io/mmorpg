require "rails_helper"

RSpec.describe Chat::SpamThrottler do
  let(:user) { create(:user) }
  let(:channel) { create(:chat_channel, channel_type: :global) }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  subject(:throttler) do
    described_class.new(user:, channel:, cache:, window: 1.minute, limit: 2)
  end

  it "allows messages within the limit" do
    expect { throttler.check! }.not_to raise_error
    expect { throttler.check! }.not_to raise_error
  end

  it "raises when the rate limit is exceeded" do
    2.times { throttler.check! }

    expect do
      throttler.check!
    end.to raise_error(Chat::Errors::SpamThrottledError)
  end
end
