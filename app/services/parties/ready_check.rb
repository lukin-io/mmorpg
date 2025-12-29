# frozen_string_literal: true

module Parties
  # ReadyCheck resets per-member ready states and tracks completion for dungeon prep.
  # Usage:
  #   Parties::ReadyCheck.new(party: party).start!
  #   Parties::ReadyCheck.new(party: party).resolve_if_complete!
  class ReadyCheck
    def initialize(party:)
      @party = party
    end

    def start!
      Party.transaction do
        party.update!(ready_check_state: :running, ready_check_started_at: Time.current)
        party.party_memberships.active.update_all(
          ready_state: PartyMembership.ready_states[:unknown]
        )
      end
    end

    def mark_ready!(membership, ready_state:)
      membership.update!(ready_state: ready_state.to_s)
      resolve_if_complete!
    end

    def resolve_if_complete!
      return unless party.ready_check_running?

      return if party.party_memberships.active.where(ready_state: :unknown).exists?

      party.update!(ready_check_state: :resolved)
    end

    private

    attr_reader :party
  end
end
