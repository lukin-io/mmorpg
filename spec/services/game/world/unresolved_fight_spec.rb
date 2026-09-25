# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::UnresolvedFight do
  let(:character) { create(:character) }

  it "returns a live match first" do
    match = create(:arena_match, :live)
    create(:arena_participation, character:, arena_match: match)

    expect(described_class.new(character:).match).to eq(match)
    expect(described_class.new(character:)).to be_live
  end

  it "returns a completed match without finished_at so the player can press Finish" do
    match = create(:arena_match, :completed, timed_out: true)
    create(:arena_participation, character:, arena_match: match, metadata: {})

    expect(described_class.new(character:).match).to eq(match)
    expect(described_class.new(character:)).to be_needs_finish
  end

  it "ignores completed fights the player already finished" do
    match = create(:arena_match, :completed)
    create(:arena_participation, character:, arena_match: match, metadata: {"finished_at" => Time.current.iso8601})

    expect(described_class.new(character:).match).to be_nil
  end
end
