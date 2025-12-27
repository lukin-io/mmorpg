# frozen_string_literal: true

module Game
  module Pvp
    # Purpose: Determines if PVP is allowed between two characters in a zone.
    # Uses zone.pvp_enabled and zone.pvp_mode for access control.
    # Also handles faction warfare, flag checks, and revenge windows.
    #
    # Inputs:
    #   - zone: The zone where combat would occur
    #   - attacker: Character attempting to attack
    #   - defender: Character being attacked
    #
    # Returns:
    #   Boolean or error reason
    #
    # Usage:
    #   if Game::Pvp::ZoneRules.pvp_allowed?(zone, attacker: warrior, defender: mage)
    #     # Start PVP combat
    #   end
    #
    class ZoneRules
      # PVP modes for zones
      OPEN_PVP_MODES = %w[open arena battleground faction_war].freeze
      SAFE_BIOMES = %w[city].freeze

      class << self
        # Check if PVP is allowed between two characters in a zone
        #
        # @param zone [Zone] the zone where combat occurs
        # @param attacker [Character] the attacking character
        # @param defender [Character] the defending character
        # @return [Boolean]
        def pvp_allowed?(zone, attacker:, defender:)
          result = check_pvp_allowed(zone, attacker, defender)
          result[:allowed]
        end

        # Check with detailed reason
        #
        # @return [Hash] { allowed: Boolean, reason: String }
        def check_pvp_allowed(zone, attacker, defender)
          # Can't attack yourself
          if attacker.id == defender.id
            return {allowed: false, reason: "Cannot attack yourself"}
          end

          # No zone = unsafe, require mutual flagging
          return check_flagged_pvp(attacker, defender) if zone.nil?

          # Safe biomes never allow PVP
          if safe_biome?(zone)
            return {allowed: false, reason: "PVP is not allowed in safe zones"}
          end

          # Zone has PVP explicitly enabled
          if zone.pvp_enabled?
            return check_pvp_mode(zone, attacker, defender)
          end

          # Zone PVP disabled but check mutual flagging
          check_flagged_pvp(attacker, defender)
        end

        private

        # Check PVP based on zone's pvp_mode
        def check_pvp_mode(zone, attacker, defender)
          mode = zone.pvp_mode.to_s

          case mode
          when "open", "arena", "battleground"
            {allowed: true, reason: "Zone allows open PVP"}
          when "faction_war"
            if opposing_factions?(attacker, defender)
              {allowed: true, reason: "Faction warfare is active"}
            else
              check_flagged_pvp(attacker, defender)
            end
          when "flagged"
            check_flagged_pvp(attacker, defender)
          else
            # Default: require mutual flagging
            check_flagged_pvp(attacker, defender)
          end
        end

        # Check if PVP is allowed via mutual flagging or revenge
        def check_flagged_pvp(attacker, defender)
          # Both players flagged for PVP
          if both_pvp_flagged?(attacker, defender)
            return {allowed: true, reason: "Both players are flagged for PVP"}
          end

          # Defender attacked attacker recently (revenge window)
          if revenge_window?(attacker, defender)
            return {allowed: true, reason: "Revenge attack allowed"}
          end

          {allowed: false, reason: "PVP requires mutual flagging or PVP zone"}
        end

        # Check if zone biome is a safe biome
        def safe_biome?(zone)
          biome = zone.respond_to?(:biome) ? zone.biome.to_s : ""
          SAFE_BIOMES.include?(biome)
        end

        # Check if both characters are flagged for PVP
        def both_pvp_flagged?(attacker, defender)
          pvp_flagged?(attacker) && pvp_flagged?(defender)
        end

        # Check if character is flagged for PVP
        def pvp_flagged?(character)
          return false unless character.respond_to?(:pvp_flags)

          character.pvp_flags.active.exists?
        end

        # Check if characters are in opposing factions
        def opposing_factions?(attacker, defender)
          attacker_faction = attacker.respond_to?(:faction_alignment) ? attacker.faction_alignment : nil
          defender_faction = defender.respond_to?(:faction_alignment) ? defender.faction_alignment : nil

          return false if attacker_faction.nil? || defender_faction.nil?

          # Define opposing factions
          opposites = {
            "light" => "dark",
            "dark" => "light",
            "law" => "chaos",
            "chaos" => "law"
          }

          opposites[attacker_faction.to_s] == defender_faction.to_s
        end

        # Check if attacker has a revenge window against defender
        def revenge_window?(attacker, defender)
          return false unless attacker.respond_to?(:last_attacked_by_at)

          last_attack = attacker.last_attacked_by_at&.dig(defender.id.to_s)
          return false unless last_attack

          # 5 minute revenge window
          Time.parse(last_attack) > 5.minutes.ago
        rescue StandardError
          false
        end
      end
    end
  end
end
