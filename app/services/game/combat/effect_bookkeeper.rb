# frozen_string_literal: true

module Game
  module Combat
    # EffectBookkeeper persists active buffs/debuffs on battle participants and materializes them for stat math.
    #
    # Usage:
    #   bookkeeper = Game::Combat::EffectBookkeeper.new(battle: battle)
    #   bookkeeper.apply!(participant: participant, definitions: [{name: "Shield", duration: 2, stat_changes: {"defense" => 5}}])
    #   bookkeeper.materialized_effects(participant)
    class EffectBookkeeper
      def initialize(battle:)
        @battle = battle
      end

      def apply!(participant:, definitions:)
        return unless participant && definitions.present?

        active = active_effects(participant)
        definitions.each do |definition|
          active << serialize(definition)
        end
        persist(participant, active)
      end

      def materialized_effects(participant)
        active_effects(participant).map do |payload|
          Game::Systems::Effect.new(
            name: payload["name"] || "Effect",
            duration: payload.fetch("remaining_turns", payload["duration"]).to_i,
            stat_changes: payload.fetch("stat_changes", {}).transform_keys(&:to_sym)
          )
        end
      end

      def tick!
        return unless battle

        battle.battle_participants.find_each do |participant|
          active = active_effects(participant)
          next if active.empty?

          active.each do |entry|
            remaining = entry.fetch("remaining_turns", entry["duration"]).to_i - 1
            entry["remaining_turns"] = remaining
          end
          active.reject! { |entry| entry["remaining_turns"] <= 0 }
          persist(participant, active)
        end
      end

      private

      attr_reader :battle

      def active_effects(participant)
        Array.wrap(participant&.buffs&.fetch("active", []))
      end

      def serialize(definition)
        duration = definition["duration"] || 1
        {
          "name" => definition["name"] || "Effect",
          "duration" => duration,
          "remaining_turns" => definition.fetch("remaining_turns", duration),
          "stat_changes" => definition.fetch("stat_changes", {}),
          "applied_at_turn" => battle&.turn_number
        }.compact
      end

      def persist(participant, active)
        participant.update!(buffs: participant.buffs.merge("active" => active))
      end
    end
  end
end
