# frozen_string_literal: true

module Game
  module Pvp
    # Purpose: Manages PVP flag lifecycle for characters.
    # Handles enabling/disabling PVP, auto-flagging, and cleanup.
    #
    # Inputs:
    #   - character: The character to flag
    #
    # Returns:
    #   Result with success status and flag details
    #
    # Usage:
    #   service = Game::Pvp::FlagService.new(character)
    #   service.enable_pvp!           # Enable voluntary PVP
    #   service.disable_pvp!          # Disable voluntary PVP
    #   service.auto_flag!(:hostile_action)  # Auto-flag for attacking
    #
    class FlagService
      Result = Struct.new(:success, :flag, :message, keyword_init: true)

      attr_reader :character

      def initialize(character)
        @character = character
      end

      # Enable voluntary PVP mode
      #
      # @return [Result]
      def enable_pvp!
        return failure("Already flagged for PVP") if pvp_flagged?

        flag = character.pvp_flags.create!(
          flag_type: :voluntary,
          expires_at: nil,
          source: "manual"
        )

        broadcast_pvp_status!

        Result.new(
          success: true,
          flag: flag,
          message: "PVP mode enabled. Other players can now attack you."
        )
      rescue ActiveRecord::RecordInvalid => e
        failure("Failed to enable PVP: #{e.message}")
      end

      # Disable voluntary PVP mode
      #
      # @return [Result]
      def disable_pvp!
        voluntary_flag = character.pvp_flags.active.voluntary.first
        return failure("No active PVP flag to disable") unless voluntary_flag

        # Check for combat lockout
        if in_combat_lockout?
          return failure("Cannot disable PVP during or shortly after combat")
        end

        voluntary_flag.destroy!
        broadcast_pvp_status!

        Result.new(
          success: true,
          flag: nil,
          message: "PVP mode disabled."
        )
      end

      # Auto-flag character for PVP (hostile action, zone entry, etc.)
      #
      # @param flag_type [Symbol] :hostile_action, :zone_flag, :faction_war
      # @param duration [ActiveSupport::Duration, nil] flag duration
      # @param source [String] what triggered the flag
      # @return [Result]
      def auto_flag!(flag_type, duration: nil, source: nil)
        duration ||= default_duration(flag_type)

        # Extend existing flag if present
        existing = character.pvp_flags.active.where(flag_type: flag_type).first
        if existing
          existing.extend!(duration)
          return Result.new(success: true, flag: existing, message: "PVP flag extended")
        end

        # Create new flag
        flag = character.pvp_flags.create!(
          flag_type: flag_type,
          expires_at: duration ? Time.current + duration : nil,
          source: source || flag_type.to_s
        )

        broadcast_pvp_status!

        Result.new(
          success: true,
          flag: flag,
          message: "You are now flagged for PVP (#{flag_type})"
        )
      rescue ActiveRecord::RecordInvalid => e
        failure("Failed to flag for PVP: #{e.message}")
      end

      # Flag attacker after they attack someone
      #
      # @param defender [Character] the character that was attacked
      # @return [Result]
      def flag_for_hostile_action!(defender)
        auto_flag!(
          :hostile_action,
          duration: PvpFlag::HOSTILE_ACTION_DURATION,
          source: "attacked_#{defender.id}"
        )
      end

      # Flag character for entering a PVP zone
      #
      # @param zone [Zone] the PVP zone
      # @return [Result]
      def flag_for_zone!(zone)
        auto_flag!(
          :zone_flag,
          duration: nil, # Permanent while in zone
          source: "entered_#{zone.id}"
        )
      end

      # Unflag character after leaving a PVP zone
      #
      # @return [Result]
      def unflag_for_zone!
        zone_flag = character.pvp_flags.active.zone_flag.first
        return Result.new(success: true, flag: nil, message: "No zone flag") unless zone_flag

        # Set expiry for zone linger duration
        zone_flag.update!(expires_at: Time.current + PvpFlag::ZONE_FLAG_DURATION)

        Result.new(
          success: true,
          flag: zone_flag,
          message: "Zone PVP flag will expire in #{PvpFlag::ZONE_FLAG_DURATION.to_i} seconds"
        )
      end

      # Check if character is currently flagged for PVP
      #
      # @return [Boolean]
      def pvp_flagged?
        character.pvp_flags.active.exists?
      end

      # Get all active PVP flags
      #
      # @return [ActiveRecord::Relation]
      def active_flags
        character.pvp_flags.active
      end

      # Clear all expired flags
      #
      # @return [Integer] number of flags cleared
      def clear_expired!
        character.pvp_flags.expired.delete_all
      end

      private

      def default_duration(flag_type)
        case flag_type.to_sym
        when :voluntary
          PvpFlag::VOLUNTARY_DURATION
        when :hostile_action
          PvpFlag::HOSTILE_ACTION_DURATION
        when :zone_flag
          PvpFlag::ZONE_FLAG_DURATION
        when :faction_war
          PvpFlag::FACTION_WAR_DURATION
        else
          5.minutes
        end
      end

      def in_combat_lockout?
        return false unless character.respond_to?(:last_combat_at)
        return false unless character.last_combat_at

        character.last_combat_at > 10.seconds.ago
      end

      def broadcast_pvp_status!
        return unless defined?(ActionCable)

        ActionCable.server.broadcast(
          "character:#{character.id}:status",
          {
            type: "pvp_status_changed",
            pvp_flagged: pvp_flagged?,
            flags: active_flags.map { |f| { type: f.flag_type, expires_at: f.expires_at&.iso8601 } }
          }
        )
      end

      def failure(message)
        Result.new(success: false, flag: nil, message: message)
      end
    end
  end
end
