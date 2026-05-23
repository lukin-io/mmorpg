# frozen_string_literal: true

module Arena
  class CombatLogRecorder
    BODY_PARTS = %w[head torso stomach legs].freeze

    def initialize(match)
      @match = match
      @writer = Game::Combat::LogWriter.new(arena_match: match)
    end

    def record!(entry_type:, actor:, description:, target: nil, payload: {}, action_key: nil,
      body_part: nil, outcome: nil, damage: nil, tags: [])
      occurred_at = Time.current
      actor_participation = participation_for(actor)
      target_participation = participation_for(target)
      body_part ||= infer_body_part(description)
      damage = damage.nil? ? infer_damage(description) : damage
      outcome ||= entry_type

      canonical_payload = payload.to_h.stringify_keys.merge(
        "type" => entry_type,
        "timestamp" => occurred_at.strftime("%H:%M:%S"),
        "description" => description,
        "actor_id" => actor&.id,
        "actor_name" => participant_name(actor),
        "target_id" => target&.id,
        "target_name" => participant_name(target),
        "actor_team" => actor_participation&.team,
        "target_team" => target_participation&.team,
        "action_key" => action_key,
        "body_part" => body_part,
        "outcome" => outcome
      ).compact

      entry = writer.append!(
        log_type: entry_type,
        message: description,
        payload: canonical_payload,
        round_number: match.current_turn_number.presence || 1,
        actor: actor_participation || actor,
        target: target_participation || target,
        damage: damage,
        tags: canonical_tags(entry_type, tags, action_key, body_part, outcome, canonical_payload),
        occurred_at:,
        action_key:,
        body_part:,
        outcome:,
        actor_team: actor_participation&.team,
        target_team: target_participation&.team
      )

      entry
    end

    private

    attr_reader :match, :writer

    def participation_for(record)
      case record
      when ArenaParticipation
        record
      when Character
        match.arena_participations.find_by(character: record)
      end
    end

    def participant_name(record)
      case record
      when ArenaParticipation then record.participant_name
      when Character then record.name
      else record&.try(:name)
      end
    end

    def infer_body_part(description)
      text = description.to_s
      BODY_PARTS.find do |part|
        text.match?(/\(#{Regexp.escape(part)}\)/i) ||
          text.match?(/\b#{Regexp.escape(part)}\b/i)
      end
    end

    def infer_damage(description)
      text = description.to_s
      value = text[/for -(\d+)/i, 1] ||
        text[/for (\d+) damage/i, 1] ||
        text[/lost (\d+) HP/i, 1]
      value.to_i
    end

    def canonical_tags(entry_type, tags, action_key, body_part, outcome, payload)
      ([entry_type, "arena", action_key, body_part, outcome, payload["element"]] + Array(tags))
        .compact
        .map(&:to_s)
        .reject(&:blank?)
        .uniq
    end
  end
end
