# frozen_string_literal: true

module Arena
  class CombatLogPresenter
    class << self
      def rows_for(match)
        entries = match.combat_log_entries.order(round_number: :asc, sequence: :asc).to_a
        return entries.map { |entry| row_for_entry(entry) } if entries.any?

        Array(match.metadata.to_h["combat_log"])
      end

      def row_for_entry(entry)
        payload = entry.payload.to_h
        {
          "type" => entry.log_type,
          "timestamp" => (entry.occurred_at_or_created_at || Time.current).strftime("%H:%M:%S"),
          "actor_id" => payload["actor_id"] || entry.actor_id,
          "actor_name" => payload["actor_name"],
          "description" => payload["description"] || entry.message,
          "round_number" => entry.round_number,
          "sequence" => entry.sequence,
          "damage_amount" => entry.damage_amount,
          "healing_amount" => entry.healing_amount,
          "body_part" => entry.body_part,
          "action_key" => entry.action_key,
          "outcome" => entry.outcome,
          "tags" => entry.tags
        }.compact
      end
    end
  end
end
