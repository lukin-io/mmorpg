# frozen_string_literal: true

module Combat
  class FightLogStatistics
    ELEMENTS = %w[normal fire water earth air arcane mind].freeze
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
          total_healing: participant_entries.sum(:healing_amount),
          xp_earned: 0,
          element_damages: element_damages(participant_entries)
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
          total_healing: team_entries.sum(:healing_amount),
          total_hits: team_entries.where(log_type: HIT_TYPES).count
        }
      end
    end

    def total_damage
      entries.sum(:damage_amount)
    end

    def total_healing
      entries.sum(:healing_amount)
    end

    def element_breakdown
      ELEMENTS.each_with_object({}) do |element, hash|
        element_entries = entries.where("? = ANY(tags)", element)
        damage = element_entries.sum(:damage_amount)
        hash[element] = {
          damage:,
          hits: element_entries.where(log_type: HIT_TYPES).count,
          percentage: percentage(damage, total_damage)
        }
      end
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
          total_healing: round_entries.sum(:healing_amount),
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
        total_healing:,
        element_breakdown:,
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

    def element_damages(scope)
      ELEMENTS.each_with_object({}) do |element, hash|
        element_entries = scope.where("? = ANY(tags)", element)
        hash[element] = {
          damage: element_entries.sum(:damage_amount),
          hits: element_entries.where(log_type: HIT_TYPES).count
        }
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

    def percentage(value, total)
      return 0 if total.zero?

      ((value.to_f / total) * 100).round(1)
    end
  end
end
