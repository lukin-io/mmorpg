# frozen_string_literal: true

module Game
  module Shop
    # Ashen sandbox clearance that unlocks Doctor II/III license purchases.
    # Neverlands Traumatologist quest content is not invented here: owning Healer
    # and completing this Infirmary step sets profession_unlocks.traumatologist.
    # Inputs: current character. Output: Result. Idempotent once unlocked.
    class TraumatologistClearance
      Result = Struct.new(:success, :message, keyword_init: true)
      class Unavailable < StandardError; end

      UNLOCK_KEY = "traumatologist"

      def initialize(character:)
        @character = character
      end

      def completed?
        unlocks = character.metadata.to_h["profession_unlocks"]
        unlocks.is_a?(Hash) && unlocks[UNLOCK_KEY] == true
      end

      def visible?
        character.owns_perk?(:healer)
      end

      def call
        ApplicationRecord.transaction(requires_new: true) do
          character.lock!
          character.reload
          reject!(I18n.t("game.shop.healer_perk_required")) unless character.owns_perk?(:healer)
          return Result.new(success: true, message: I18n.t("game.shop.traumatologist_already_done")) if completed?

          if character.in_combat?
            reject!(I18n.t("game.buildings.hospital_in_combat"))
          end

          unlocks = character.metadata.to_h["profession_unlocks"]
          unlocks = {} unless unlocks.is_a?(Hash)
          character.update!(
            metadata: character.metadata.to_h.merge(
              "profession_unlocks" => unlocks.merge(UNLOCK_KEY => true)
            )
          )
          Result.new(success: true, message: I18n.t("game.shop.traumatologist_completed"))
        end
      rescue Unavailable => error
        Result.new(success: false, message: error.message)
      end

      private

      attr_reader :character

      def reject!(message)
        raise Unavailable, message
      end
    end
  end
end
