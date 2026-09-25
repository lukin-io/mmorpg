# frozen_string_literal: true

module Game
  module World
    # Clears sticky ambush chrome and zero-HP soft-locks without silently
    # dismissing a completed fight the player still needs to Finish.
    class DismissCompletedFight
      Result = Struct.new(:dismissed, :recovery, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def call
        dismissed = false
        recovery = nil

        unresolved = UnresolvedFight.new(character:).match
        if unresolved&.live?
          # Never auto-finish a live fight — player must return to the arena UI.
          dismissed = true if clear_stale_pulse_ambushes!
          return Result.new(dismissed:, recovery: nil)
        end

        if character.in_combat? && unresolved.nil?
          character.exit_combat!
          dismissed = true
        end

        dismissed = true if clear_stale_pulse_ambushes!

        recovery = DefeatRecovery.new(character:).call if character.reload.current_hp.to_i <= 0 && unresolved.nil?
        Result.new(dismissed:, recovery:)
      end

      private

      attr_reader :character

      def clear_stale_pulse_ambushes!
        return false if character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?

        cleared = false
        remembered_id = character.metadata.to_h.dig("live_ambush", "tile_npc_id")
        if remembered_id
          npc = TileNpc.find_by(id: remembered_id)
          if npc && ambush_npc?(npc)
            npc.destroy!
            cleared = true
          end
        end

        position = character.position
        if position
          npc = TileNpc.find_by(zone: position.zone.name, x: position.x, y: position.y)
          if npc && ambush_npc?(npc)
            npc.destroy!
            cleared = true
          end
        end

        TileNpc.where("npc_key LIKE ?", "ashen_ambush_%").find_each do |npc|
          next if live_match_owns_tile_npc?(npc.id)

          npc.destroy!
          cleared = true
        rescue ActiveRecord::RecordNotFound
          next
        end

        if cleared && character.metadata.to_h["live_ambush"].present?
          character.update!(
            metadata: character.metadata.to_h.except("live_ambush")
          )
        end

        cleared
      end

      def ambush_npc?(npc)
        meta = npc.metadata.to_h
        npc.npc_key.to_s.start_with?("ashen_ambush_") ||
          meta["source"].to_s == "world_live_ambush" ||
          meta["ambush_label"].present?
      end

      def live_match_owns_tile_npc?(tile_npc_id)
        ArenaMatch.active.where("metadata->>'tile_npc_id' = ?", tile_npc_id.to_s).exists?
      end
    end
  end
end
