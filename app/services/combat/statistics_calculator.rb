# frozen_string_literal: true

module Combat
  # Calculates combat statistics from log entries.
  #
  # Provides damage/healing breakdown by:
  # - Participant
  # - Element type (normal, fire, water, earth, air, arcane)
  # - Hit counts
  # - XP earned
  #
  # @example Get battle statistics
  #   stats = Combat::StatisticsCalculator.new(battle)
  #   stats.by_participant
  #   stats.total_damage
  #   stats.element_breakdown("fire")
  #
  class StatisticsCalculator
    ELEMENTS = %w[normal fire water earth air arcane].freeze

    attr_reader :battle, :entries

    def initialize(battle)
      @battle = battle
      @entries = battle.combat_log_entries.includes(:ability)
    end

    # Get statistics grouped by participant
    def by_participant
      participants = battle.battle_participants.includes(:character, :npc_template)

      participants.map do |participant|
        participant_entries = entries.where(actor_id: participant.id)

        element_damages = ELEMENTS.each_with_object({}) do |element, hash|
          element_entries = participant_entries.where("? = ANY(tags)", element)
          hash[element] = {
            damage: element_entries.sum(:damage_amount),
            hits: element_entries.where(log_type: "attack").count
          }
        end

        {
          id: participant.id,
          name: participant.combatant_name,
          team: participant.team,
          level: participant.character&.level || participant.npc_template&.level || 1,
          is_alive: participant.is_alive,
          visible: participant.participant_type != "invisible",
          element_damages: element_damages,
          total_damage: participant_entries.sum(:damage_amount),
          total_hits: participant_entries.where(log_type: "attack").count,
          total_healing: participant_entries.sum(:healing_amount),
          xp_earned: calculate_xp_for(participant)
        }
      end
    end

    # Get team statistics
    def by_team
      {
        alpha: team_stats("alpha"),
        beta: team_stats("beta")
      }
    end

    # Total damage dealt in battle
    def total_damage
      entries.sum(:damage_amount)
    end

    # Total healing in battle
    def total_healing
      entries.sum(:healing_amount)
    end

    # Damage breakdown by element
    def element_breakdown
      ELEMENTS.each_with_object({}) do |element, hash|
        element_entries = entries.where("? = ANY(tags)", element)
        hash[element] = {
          damage: element_entries.sum(:damage_amount),
          hits: element_entries.where(log_type: "attack").count,
          percentage: calculate_percentage(element_entries.sum(:damage_amount), total_damage)
        }
      end
    end

    # Body part targeting statistics
    def body_part_breakdown
      %w[head torso stomach legs].each_with_object({}) do |part, hash|
        part_entries = entries.where("? = ANY(tags)", part)
        hash[part] = {
          attacks: part_entries.where(log_type: "attack").count,
          damage: part_entries.sum(:damage_amount),
          blocked: part_entries.where(log_type: "block").count
        }
      end
    end

    # Round-by-round summary
    def round_summary
      (1..battle.round_number).map do |round|
        round_entries = entries.where(round_number: round)
        {
          round: round,
          total_damage: round_entries.sum(:damage_amount),
          total_healing: round_entries.sum(:healing_amount),
          events: round_entries.count
        }
      end
    end

    # Get top damage dealers
    def top_damage_dealers(limit: 5)
      by_participant.sort_by { |p| -p[:total_damage] }.first(limit)
    end

    # Get top healers
    def top_healers(limit: 5)
      by_participant.sort_by { |p| -p[:total_healing] }.first(limit)
    end

    # Battle duration
    def duration
      return nil unless battle.started_at

      end_time = battle.ended_at || Time.current
      end_time - battle.started_at
    end

    # Full statistics payload for export
    def to_hash
      {
        battle_id: battle.id,
        battle_type: battle.battle_type,
        status: battle.status,
        rounds: battle.round_number,
        duration_seconds: duration&.to_i,
        total_damage: total_damage,
        total_healing: total_healing,
        element_breakdown: element_breakdown,
        body_part_breakdown: body_part_breakdown,
        participants: by_participant,
        teams: by_team,
        round_summary: round_summary
      }
    end

    private

    def team_stats(team)
      team_participants = battle.battle_participants.where(team: team)
      team_entries = entries.where(actor_id: team_participants.pluck(:id))

      {
        members: team_participants.count,
        alive: team_participants.where(is_alive: true).count,
        total_damage: team_entries.sum(:damage_amount),
        total_healing: team_entries.sum(:healing_amount),
        total_hits: team_entries.where(log_type: "attack").count
      }
    end

    def calculate_xp_for(participant)
      return 0 unless participant.character && battle.completed?

      base_xp = 50
      rounds_bonus = battle.round_number * 10
      damage_bonus = (participant.damage_dealt&.dig("total") || 0) / 10
      winner_bonus = participant.is_alive ? 100 : 0

      base_xp + rounds_bonus + damage_bonus + winner_bonus
    end

    def calculate_percentage(value, total)
      return 0 if total.zero?
      ((value.to_f / total) * 100).round(1)
    end
  end
end
