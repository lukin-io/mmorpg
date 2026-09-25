# frozen_string_literal: true

module Game
  module World
    # Finds a fight the player must still acknowledge: a live match, or a
    # completed match they have not pressed Finish on yet.
    class UnresolvedFight
      def initialize(character:)
        @character = character
      end

      def match
        live || completed_unfinished
      end

      def live?
        live.present?
      end

      def needs_finish?
        completed_unfinished.present?
      end

      private

      attr_reader :character

      def live
        @live ||= character.arena_participations
          .joins(:arena_match)
          .merge(ArenaMatch.active)
          .order("arena_participations.created_at DESC")
          .first
          &.arena_match
      end

      def completed_unfinished
        @completed_unfinished ||= begin
          participation = character.arena_participations
            .joins(:arena_match)
            .merge(ArenaMatch.completed)
            .order("arena_participations.created_at DESC")
            .includes(:arena_match)
            .detect { |row| row.metadata.to_h["finished_at"].blank? }
          participation&.arena_match
        end
      end
    end
  end
end
