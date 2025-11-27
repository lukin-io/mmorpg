# frozen_string_literal: true

# Helpers for arena season views.
module ArenaSeasonsHelper
  def current_character_rank(season)
    ranking = season.arena_rankings.find_by(character: current_character)
    return "Unranked" unless ranking

    season.arena_rankings.where("rating > ?", ranking.rating).count + 1
  end

  def current_character_rating(season)
    ranking = season.arena_rankings.find_by(character: current_character)
    ranking&.rating || 1000
  end

  def current_character_rank_tier(season)
    rank = current_character_rank(season)
    return "unranked" if rank == "Unranked"

    rank_tier(rank.to_i)
  end

  def current_character_matches(season)
    season.arena_matches
      .joins(:arena_participations)
      .where(arena_participations: { character: current_character })
      .count
  end

  def rank_tier(rank)
    case rank
    when 1 then "champion"
    when 2..10 then "gladiator"
    when 11..100 then "combatant"
    else "participant"
    end
  end
end

