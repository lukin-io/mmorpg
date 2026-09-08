# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::LocalContext do
  let(:character) { create(:character) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }

  it "preserves a current visit on reload and repairs a stale context using server time" do
    now = Time.current.change(usec: 0)
    first = described_class.new(character:, clock: -> { now }).synchronize!
    second = described_class.new(character:, clock: -> { now + 10 }).synchronize!
    expect(second).to eq(first)

    position.update!(x: 5)
    current = described_class.new(character:, clock: -> { now + 20 }).synchronize!
    expect(current.entered_at).to eq(now + 20)
    expect(current.key).not_to eq(first.key)
  end

  it "does not create a location for missing positions or characters" do
    position.destroy!
    character.reload
    expect(described_class.new(character:).synchronize!).to be_nil
    expect(described_class.new(character: nil).synchronize!).to be_nil
  end

  it "does not accept an arbitrary router local key or label" do
    channel = Chat::ChannelRouter.new(user: character.user).resolve(scope: :local, context: {local_key: "remote", name: "Forged"})
    expect(channel.metadata).to eq("location_key" => described_class.new(character:).key)
    expect(channel.name).to eq("Local")
  end
end
