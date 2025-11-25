# frozen_string_literal: true

module Arena
  # Matchmaker pairs queued participants into a new ArenaMatch and records enrollments.
  # Usage:
  #   Arena::Matchmaker.new.queue!(participants: [...], match_type: :duel)
  # Returns:
  #   ArenaMatch instance.
  class Matchmaker
    def initialize(season: ArenaSeason.current.first)
      @season = season
    end

    def queue!(participants:, match_type:, zone: nil)
      raise ArgumentError, "At least two participants required" if participants.size < 2

      ArenaMatch.transaction do
        match = ArenaMatch.create!(
          arena_season: season,
          match_type: match_type,
          status: :matching,
          zone: zone,
          metadata: {"queued_at" => Time.current.iso8601}
        )

        participants.each do |participant|
          match.arena_participations.create!(
            character: participant.fetch(:character),
            user: participant.fetch(:user),
            team: participant.fetch(:team),
            joined_at: Time.current
          )
        end

        match.update!(status: :pending)
        match
      end
    end

    private

    attr_reader :season
  end
end
