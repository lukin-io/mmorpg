# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::LocalActionState do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:offer) do
    create(:world_action_offer, :accepted, character:, zone:, x: 5, y: 5,
      metadata: {
        "local_action_ends_at" => (Time.current + 28.seconds).iso8601(6),
        "local_action_result" => "There is no useful vegetation in this area."
      })
  end

  around { |example| freeze_time { example.run } }

  it "keeps accepted work and its original deadline before expiry" do
    deadline = offer.local_action_ends_at

    state = described_class.new(character:, clock: -> { deadline - 1.second }).call

    expect(state).to eq(offer)
    expect(offer.reload).to be_accepted
    expect(offer.local_action_ends_at).to eq(deadline)
    expect(offer.completed_at).to be_nil
  end

  [0, 1].each do |elapsed|
    it "completes work #{elapsed} seconds after the deadline without resources or movement" do
      deadline = offer.local_action_ends_at
      now = deadline + elapsed.seconds

      expect { expect(described_class.new(character:, clock: -> { now }).call).to be_nil }
        .not_to change(InventoryItem, :count)

      expect(offer.reload).to be_completed
      expect(offer.completed_at).to eq(now)
      expect(position.reload).to have_attributes(x: 5, y: 5)
    end
  end

  it "retains the first completed timestamp on repeated reads" do
    deadline = offer.local_action_ends_at
    described_class.new(character:, clock: -> { deadline }).call

    expect(described_class.new(character:, clock: -> { deadline + 10.seconds }).call).to be_nil
    expect(offer.reload.completed_at).to eq(deadline)
  end

  it "does not read or change another character's pending action" do
    offer
    other_character = create(:character)

    expect(described_class.new(character: other_character).call).to be_nil
    expect(offer.reload).to be_accepted
  end

  it "fails work whose exact source position no longer matches" do
    offer
    position.update!(x: 6)

    expect(described_class.new(character:).call).to be_nil
    expect(offer.reload).to be_failed
    expect(position.reload.x).to eq(6)
  end

  it "cancels the timer when an active fight supersedes it" do
    offer
    match = create(:arena_match, :live, zone:)
    create(:arena_participation, arena_match: match, character:, user: character.user)

    expect(described_class.new(character:).call).to be_nil
    expect(offer.reload).to be_cancelled
    expect(offer.completed_at).to be_nil
  end

  it "fails a malformed persisted deadline safely" do
    offer.update_columns(metadata: offer.metadata.merge("local_action_ends_at" => "invalid"))

    expect(described_class.new(character:).call).to be_nil
    expect(offer.reload).to be_failed
    expect(offer.error_message).to include("deadline is invalid")
  end

  it "ignores ordinary accepted offers which do not represent timed work" do
    ordinary_offer = create(:world_action_offer, :accepted, character:, zone:, x: 5, y: 5)

    expect(described_class.new(character:).call).to be_nil
    expect(ordinary_offer.reload).to be_accepted
  end
end
