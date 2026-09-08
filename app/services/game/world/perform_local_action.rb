# frozen_string_literal: true

module Game
  module World
    # Starts a captured current-cell action from an accepted owned offer. Under
    # the character/offer lock it revalidates the cell, resolves interruption,
    # and atomically persists the immediate result, configured deadline and
    # Drink's fatigue recovery. Retrying a started offer returns its original
    # result without applying recovery again. No resource or currency is awarded.
    class PerformLocalAction
      Result = Struct.new(:success, :message, :local_action, :action_offer, :interruption, keyword_init: true)

      def initialize(character:, tile:, local_action_type:, action_offer:, clock: -> { Time.current }, rules: Rules.default)
        @character = character
        @tile = tile
        @local_action_type = local_action_type.to_s
        @action_offer = action_offer
        @clock = clock
        @rules = rules
      end

      def call
        character.with_lock do
          character.reload
          @tile = MapTileTemplate.find_by(id: tile&.id)
          next failure("Local action is no longer available.") unless tile
          next failure("Local action is not implemented.") unless MapTileTemplate.local_action_implemented?(local_action_type)

          @action_offer = WorldActionOffer.where(character:).lock.find_by(id: action_offer&.id)
          next failure("Action offer does not match this local action.") unless offer_matches_action?

          if action_offer.local_action_ends_at && (action_offer.accepted? || action_offer.completed?)
            LocalActionState.new(character:, clock:).call
            action_offer.reload
            next success if action_offer.accepted? || action_offer.completed?
          end
          next failure("Action offer is no longer accepted.") unless action_offer.accepted?
          next failure("Local action is not on the current cell.") unless tile_matches_position? && action_offer.matches_position?(character.position)
          next failure("A local action is still in progress.") if LocalActionState.new(character:, clock:).call

          local_action = tile.local_action(local_action_type)
          next failure("Local action is no longer available.") unless local_action

          interruption = InterruptAction.new(character:).call
          if interruption.interrupted?
            action_offer.complete!
            next Result.new(success: true, message: interruption.message, local_action:, action_offer:, interruption:)
          end

          now = clock.call
          action_offer.update!(metadata: action_offer.metadata.to_h.merge(
            "local_action_ends_at" => (now + rules.local_action_duration_seconds(local_action_type)).iso8601(6),
            "local_action_result" => local_action["result_message"].presence || MapTileTemplate.default_local_action_message(local_action_type),
            "label" => local_action["label"].presence || MapTileTemplate.default_local_action_label(local_action_type)
          ).merge(apply_effect(at: now)))
          cancel_sibling_offers!(now)

          success(local_action:)
        end
      end

      private

      attr_reader :character, :tile, :local_action_type, :action_offer, :clock, :rules

      def apply_effect(at:)
        return {} unless local_action_type == "drinking"

        # Nature Child's 4-point value is preserved in Rules for its future
        # perk implementation. No unsupported perk flag grants an effect here.
        points = rules.drinking_fatigue_recovery_points
        applied = Characters::FatigueService.new(character:, rules:).recover!(amount: points, at:)
        {
          "fatigue_recovery_points" => points,
          "fatigue_recovery_applied" => applied,
          "fatigue_recovered_at" => at.iso8601(6)
        }
      end

      def offer_matches_action?
        action_offer &&
          action_offer.action_type == MapTileTemplate.world_action_type_for(local_action_type) &&
          action_offer.target_type == "MapTileTemplate" &&
          action_offer.target_id == tile.id
      end

      def tile_matches_position?
        position = character.position
        position.present? &&
          position.zone.name == tile.zone &&
          position.x == tile.x &&
          position.y == tile.y
      end

      def failure(message)
        Result.new(success: false, message:, local_action: nil)
      end

      def success(local_action: nil)
        Result.new(success: true, message: action_offer.local_action_result, local_action:, action_offer:)
      end

      def cancel_sibling_offers!(now)
        WorldActionOffer.offered.where(character:).update_all(
          status: WorldActionOffer.statuses.fetch("cancelled"), updated_at: now
        )
        MovementCommand.offered.where(character:).update_all(
          status: MovementCommand.statuses.fetch("cancelled"), processed_at: now, updated_at: now
        )
      end
    end
  end
end
