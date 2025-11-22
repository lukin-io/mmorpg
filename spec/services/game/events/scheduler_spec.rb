# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Events::Scheduler do
  let(:game_event) { create(:game_event, slug: "wintertide", starts_at: 1.day.from_now, ends_at: 2.days.from_now) }

  describe "#spawn_instance!" do
    it "creates an event instance with optional tournament metadata" do
      bracket = create(:competition_bracket, game_event:)
      scheduler = described_class.new(game_event)

      instance = scheduler.spawn_instance!(
        tournament: {competition_bracket_id: bracket.id, name: "Winter Cup"}
      )

      expect(instance).to be_persisted
      expect(instance.arena_tournaments.first.name).to eq("Winter Cup")
    end
  end
end
