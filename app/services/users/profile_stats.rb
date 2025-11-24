# frozen_string_literal: true

module Users
  # ProfileStats aggregates combat/quest/ladder metrics for the public profile JSON payload.
  class ProfileStats
    def initialize(user:)
      @user = user
    end

    def as_json(*)
      {
        damage_dealt: total_damage_dealt,
        quests_completed: quests_completed,
        top_arena_rating: top_arena_rating
      }
    end

    private

    attr_reader :user

    def character_ids
      @character_ids ||= user.characters.pluck(:id)
    end

    def total_damage_dealt
      return 0 if character_ids.empty?

      CombatLogEntry
        .where("payload ->> 'attacker_id' IN (?)", character_ids.map(&:to_s))
        .sum(Arel.sql("(payload ->> 'total_damage')::integer"))
        .to_i
    end

    def quests_completed
      return 0 if character_ids.empty?

      QuestAssignment.where(character_id: character_ids, status: :completed).count
    end

    def top_arena_rating
      return 0 if character_ids.empty?

      ArenaRanking.where(character_id: character_ids, ladder_type: "arena").maximum(:rating).to_i
    end
  end
end
