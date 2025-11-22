# frozen_string_literal: true

module Game
  module Combat
    # ArenaLadder applies Elo-style ranking adjustments after arena battles.
    #
    # Usage:
    #   Game::Combat::ArenaLadder.new(battle:).apply!(winner: character)
    #
    # Returns:
    #   Hash of updated ratings.
    class ArenaLadder
      K_FACTOR = 32

      def initialize(battle:)
        @battle = battle
      end

      def apply!(winner:)
        return {} unless battle&.battle_type == "arena"

        winner_ranking = find_or_create_ranking(winner)
        loser = opposing_character(winner)
        loser_ranking = loser ? find_or_create_ranking(loser) : nil

        expected_winner = expected_score(winner_ranking.rating, loser_ranking&.rating || winner_ranking.rating)
        winner_delta = (K_FACTOR * (1 - expected_winner)).round
        loser_delta = loser_ranking ? (K_FACTOR * (0 - (1 - expected_winner))).round : 0

        winner_ranking.update!(
          rating: winner_ranking.rating + winner_delta,
          wins: winner_ranking.wins + 1,
          streak: winner_ranking.streak + 1
        )

        if loser_ranking
          loser_ranking.update!(
            rating: [loser_ranking.rating + loser_delta, 1].max,
            losses: loser_ranking.losses + 1,
            streak: 0
          )
        end

        {
          winner_rating: winner_ranking.rating,
          loser_rating: loser_ranking&.rating
        }
      end

      private

      attr_reader :battle

      def find_or_create_ranking(character)
        character.arena_ranking || character.create_arena_ranking!
      end

      def opposing_character(winner)
        battle.battle_participants
          .where.not(character_id: winner.id)
          .where.not(character_id: nil)
          .first
          &.character
      end

      def expected_score(rating_a, rating_b)
        1.0 / (1 + 10**((rating_b - rating_a) / 400.0))
      end
    end
  end
end
