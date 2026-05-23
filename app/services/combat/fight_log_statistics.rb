# frozen_string_literal: true

module Combat
  class FightLogStatistics
    HIT_TYPES = %w[attack damage critical].freeze

    attr_reader :fight, :entries

    def initialize(fight)
      @fight = fight
      @entries = fight.combat_log_entries
    end

    def by_participant
      participants.map do |participant|
        participant_entries = entries_for(participant)
        {
          id: participant.id,
          name: participant_name(participant),
          team: participant_team(participant),
          level: participant_level(participant),
          is_alive: participant_alive?(participant),
          visible: true,
          total_damage: participant_entries.sum(:damage_amount),
          total_hits: participant_entries.where(log_type: HIT_TYPES).count,
          xp_earned: 0
        }
      end
    end

    def by_team
      participants.group_by { |participant| participant_team(participant) }.transform_values do |team_participants|
        ids = team_participants.map(&:id)
        team_entries = entries.where(actor_type: "ArenaParticipation", actor_id: ids)
        {
          members: team_participants.count,
          alive: team_participants.count { |participant| participant_alive?(participant) },
          total_damage: team_entries.sum(:damage_amount),
          total_hits: team_entries.where(log_type: HIT_TYPES).count
        }
      end
    end

    def total_damage
      entries.sum(:damage_amount)
    end

    def body_part_breakdown
      %w[head torso stomach legs].each_with_object({}) do |part, hash|
        part_entries = entries.where("body_part = ? OR ? = ANY(tags)", part, part)
        hash[part] = {
          attacks: part_entries.where(log_type: HIT_TYPES).count,
          damage: part_entries.sum(:damage_amount),
          blocked: part_entries.where(log_type: %w[block block_failed]).count
        }
      end
    end

    def round_summary
      max_round = [entries.maximum(:round_number).to_i, 1].max
      (1..max_round).map do |round|
        round_entries = entries.where(round_number: round)
        {
          round:,
          total_damage: round_entries.sum(:damage_amount),
          events: round_entries.count
        }
      end
    end

    def duration
      return nil unless fight.started_at

      (fight.ended_at || Time.current) - fight.started_at
    end

    def to_hash
      {
        fight_id: fight.id,
        fight_type: fight_type,
        status: fight.status,
        duration_seconds: duration&.to_i,
        total_damage:,
        body_part_breakdown:,
        participants: by_participant,
        teams: by_team,
        round_summary:
      }
    end

    private

    def participants
      @participants ||= fight.arena_participations.includes(:character, :npc_template).to_a
    end

    def entries_for(participant)
      if participant.character_id.present?
        entries.where(
          "(actor_type = ? AND actor_id = ?) OR (actor_type = ? AND actor_id = ?)",
          "ArenaParticipation", participant.id, "Character", participant.character_id
        )
      else
        entries.where(actor_type: "ArenaParticipation", actor_id: participant.id)
      end
    end

    def fight_type
      fight.match_type
    end

    def participant_name(participant)
      participant.participant_name
    end

    def participant_team(participant)
      participant.team
    end

    def participant_level(participant)
      participant.participant_level
    end

    def participant_alive?(participant)
      participant.current_hp.positive?
    end
  end
end
