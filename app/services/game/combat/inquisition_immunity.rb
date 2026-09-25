# frozen_string_literal: true

module Game
  module Combat
    # Inquisition (INQ) members cannot be assaulted in world PvP, arena accept,
    # or manual/custom duel flows. Matches ashen-veil inquisition_immune gate.
    class InquisitionImmunity
      METADATA_KEY = "inquisition_member"
      CLAN_TAG = "INQ"

      def self.inquisitor?(character)
        return false unless character

        meta = character.metadata.to_h
        return true if meta[METADATA_KEY] == true || meta[METADATA_KEY].to_s == "true"
        return true if meta["clan_tag"].to_s.upcase == CLAN_TAG
        return true if meta["clan_system_kind"].to_s == "inquisition"

        false
      end

      def self.blocked?(attacker:, defender:)
        return false unless attacker && defender
        return false if attacker.id == defender.id

        inquisitor?(defender)
      end

      def self.deny!(attacker:, defender:)
        return unless blocked?(attacker:, defender:)

        raise Denial, I18n.t("game.world.inquisition_immune")
      end

      class Denial < StandardError; end
    end
  end
end
