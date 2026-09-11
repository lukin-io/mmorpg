# frozen_string_literal: true

module Game
  module Shop
    # Reads explicit license definitions and owned, timed license permissions. A
    # purchase activates its granted permission immediately for the described
    # duration; possession of an item whose name contains "license" grants none.
    class LicenseRules
      DURATIONS = {"trading" => [3, 10, 30], "doctor" => [5, 10, 15]}.freeze

      def initialize(character:, active_licenses: nil)
        @character = character
        @active_licenses = active_licenses
      end

      def self.definition(template)
        value = template.enhancement_rules.to_h["license"]
        return unless value.is_a?(Hash)
        return unless DURATIONS.key?(value["kind"])
        return unless value["duration_days"].is_a?(Integer) && value["duration_days"].positive?

        durations = DURATIONS.fetch(value["kind"])
        return unless value["tier"].is_a?(Integer) && value["tier"].between?(1, 3)
        return unless durations[value["tier"] - 1] == value["duration_days"]

        value
      end

      def self.trading_skill(character)
        skills = character&.metadata.to_h["profession_skills"]
        value = skills["trading"] if skills.is_a?(Hash)
        value.is_a?(Integer) && value >= 0 ? value : 0
      end

      def purchase_block_reason(template)
        return unless template.enhancement_rules.to_h.key?("license")

        license = self.class.definition(template)
        return "This license is unavailable." unless license && template.stack_limit == 1
        return "Merchant perk required." if license["kind"] == "trading" && !character.owns_perk?(:merchant)
        return "Merchant qualification required." if license["kind"] == "trading" && !profession_unlocked?("merchant")
        return "Healer perk required." if license["kind"] == "doctor" && !character.owns_perk?(:healer)
        if license["kind"] == "doctor" && license["tier"] > 1 && !profession_unlocked?("traumatologist")
          return "Traumatologist quest required."
        end
        return "You already have an active #{license['kind']} license." if active?(license["kind"])

        nil
      end

      def active?(kind, at: Time.current)
        if active_licenses
          return active_licenses.any? do |license|
            license.character_id == character.id && license.kind == kind.to_s && license.active?(at:)
          end
        end

        CharacterLicense.active_at(at).exists?(character:, kind: kind.to_s)
      end

      # Called inside the purchase transaction instead of inventory acquisition.
      # The clock is supplied once by the trade to keep start and expiry exact.
      def activate!(template:, offer:, at: Time.current)
        license = self.class.definition(template)
        CharacterLicense.create!(character:, item_template: template, world_action_offer: offer,
          kind: license.fetch("kind"), tier: license.fetch("tier"), name: template.name,
          starts_at: at, expires_at: at + license.fetch("duration_days").days)
      end

      private

      attr_reader :character, :active_licenses

      def profession_unlocked?(key)
        unlocks = character.metadata.to_h["profession_unlocks"]
        unlocks.is_a?(Hash) && unlocks[key] == true
      end
    end
  end
end
