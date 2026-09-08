# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaApplication, "lifecycle scopes" do
  let(:room) { create(:arena_room) }
  let(:applicant) { create(:character) }

  describe ".active" do
    it "contains only open applications and matched applications whose fight is active" do
      open_application = create(:arena_application, :open, arena_room: room, applicant:)
      pending_match = create(:arena_match, :countdown, arena_room: room)
      pending_application = create(
        :arena_application,
        :matched,
        arena_room: room,
        applicant:,
        arena_match: pending_match
      )
      live_match = create(:arena_match, :live, arena_room: room)
      live_application = create(
        :arena_application,
        :matched,
        arena_room: room,
        applicant: create(:character),
        arena_match: live_match
      )
      completed_match = create(:arena_match, :completed, arena_room: room)
      completed_application = create(
        :arena_application,
        :matched,
        arena_room: room,
        applicant: create(:character),
        arena_match: completed_match
      )
      orphaned_matched_application = create(
        :arena_application,
        :matched,
        arena_room: room,
        applicant: create(:character)
      )
      started_application = create(
        :arena_application,
        :started,
        arena_room: room,
        applicant: create(:character),
        arena_match: live_match
      )
      cancelled_application = create(
        :arena_application,
        :cancelled,
        arena_room: room,
        applicant: create(:character)
      )
      expired_application = create(
        :arena_application,
        :expired,
        arena_room: room,
        applicant: create(:character)
      )

      expect(described_class.active).to contain_exactly(
        open_application,
        pending_application,
        live_application
      )
      expect(described_class.active).not_to include(
        completed_application,
        orphaned_matched_application,
        started_application,
        cancelled_application,
        expired_application
      )
    end
  end
end
