# frozen_string_literal: true

module Combat
  # Read-only public projection of one ArenaMatch and its persisted results.
  # Participant/team damage uses credited participation totals when present;
  # older rows fall back to logged damage, which can include overkill. Physical
  # and total damage share the current bounded damage bucket. Missing defeat
  # counters stay unknown rather than being inferred from hit events.
  # Body-part/round breakdowns and Hits remain raw log-event diagnostics.
  class FightLogStatistics
    HIT_TYPES = %w[attack damage critical].freeze

    attr_reader :fight, :entries

    def initialize(fight)
      @fight = fight
      @entries = fight.combat_log_entries
    end

    def by_participant
      @by_participant ||= participants.map do |participant|
        metadata = participant.metadata.to_h
        damage = if metadata.key?("damage_dealt")
          metadata["damage_dealt"].to_i
        else
          actor_total(damage_by_actor, participant)
        end
        {
          id: participant.id,
          name: participant_name(participant),
          team: participant_team(participant),
          level: participant_level(participant),
          is_alive: participant_alive?(participant),
          visible: true,
          physical_damage: metadata.fetch("damage_by_element", {}).fetch("physical", metadata.key?("damage_by_element") ? 0 : damage),
          magical_damage: metadata.fetch("damage_by_element", {}).except("physical").values.sum,
          total_damage: damage,
          opponents_defeated: metadata["opponents_defeated"]&.to_i,
          total_hits: actor_total(hits_by_actor, participant),
          xp_earned: experience_for(participant)
        }
      end
    end

    def by_team
      by_participant.group_by { |row| row[:team] }.transform_values do |rows|
        defeated_counts = rows.map { |row| row[:opponents_defeated] }
        {
          members: rows.size,
          alive: rows.count { |row| row[:is_alive] },
          physical_damage: rows.sum { |row| row[:physical_damage] },
          magical_damage: rows.sum { |row| row[:magical_damage] },
          total_damage: rows.sum { |row| row[:total_damage] },
          opponents_defeated: defeated_counts.include?(nil) ? nil : defeated_counts.sum,
          total_hits: rows.sum { |row| row[:total_hits] },
          xp_earned: rows.sum { |row| row[:xp_earned] }
        }
      end
    end

    def total_damage
      # Preserve the old whole-log total (including unattributed events) when
      # no participant has recorded credited damage. Mixed older/newer rows
      # otherwise use the same per-participant fallback as the visible table.
      return damage_by_actor.values.sum unless participants.any? { |participant| participant.metadata.to_h.key?("damage_dealt") }

      by_participant.sum { |row| row[:total_damage] }
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

    def damage_by_actor
      @damage_by_actor ||= entries.reorder(nil).group(:actor_type, :actor_id).sum(:damage_amount)
    end

    def hits_by_actor
      @hits_by_actor ||= entries.reorder(nil).where(log_type: HIT_TYPES).group(:actor_type, :actor_id).count
    end

    def actor_total(totals, participant)
      amount = totals.fetch(["ArenaParticipation", participant.id], 0)
      amount += totals.fetch(["Character", participant.character_id], 0) if participant.character_id.present?
      amount
    end

    def experience_for(participant)
      return participant.metadata["experience_awarded"].to_i if participant.metadata.to_h.key?("experience_awarded")

      experience = (@experience ||= fight.metadata.to_h.dig("rewards", "experience").to_h)
      return 0 unless participant.character_id.present? && experience["character_id"].to_i == participant.character_id

      experience["amount"].to_i
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
      return false if participant.defeat?

      participant.current_hp.positive?
    end
  end
end
