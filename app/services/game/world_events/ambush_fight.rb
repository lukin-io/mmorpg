# frozen_string_literal: true

module Game
  module WorldEvents
    # Materializes a personal ambush TileNpc on the victim's cell and starts combat.
    class AmbushFight
      Result = Struct.new(:ok, :match, :message, keyword_init: true)

      def initialize(character:, npc_label:, rng: Random.new)
        @character = character
        @npc_label = npc_label.to_s
        @rng = rng
      end

      def call
        position = character.position
        return Result.new(ok: false, message: "no_position") unless position

        template = find_or_create_template!
        tile_npc = ensure_tile_npc!(position, template)
        return Result.new(ok: false, message: "cell_occupied") unless tile_npc

        match = Game::World::StartNpcFight.new(
          character:,
          tile_npc:,
          return_context: "world",
          rng:,
          allow_off_cell: true
        ).call

        unless match
          clear_ambush!(tile_npc)
          return Result.new(ok: false, message: "no_match")
        end

        character.update!(
          metadata: character.metadata.to_h.merge(
            "live_ambush" => {
              "match_id" => match.id,
              "tile_npc_id" => tile_npc.id,
              "npc_label" => npc_label,
              "resolved" => true
            }
          )
        )
        Result.new(ok: true, match:, message: "started")
      rescue Game::World::StartNpcFight::FightViolationError => error
        clear_ambush!(tile_npc) if defined?(tile_npc) && tile_npc
        Result.new(ok: false, message: error.message)
      end

      private

      attr_reader :character, :npc_label, :rng

      def find_or_create_template!
        key = "ashen_ambush_#{npc_label.parameterize(separator: "_").presence || "shadow"}"
        NpcTemplate.find_or_create_by!(npc_key: key) do |row|
          row.name = npc_label
          row.level = [character.level.to_i, 1].max
          row.role = "hostile"
          row.dialogue = "…"
          row.metadata = {
            "source" => "world_live_ambush",
            "personal_instance" => true,
            "max_hp" => 80 + (character.level.to_i * 12),
            "attack" => 8 + character.level.to_i,
            "defense" => 4 + (character.level.to_i / 2)
          }
        end
      end

      def ensure_tile_npc!(position, template)
        zone = position.zone.name
        x = position.x
        y = position.y
        existing = TileNpc.find_by(zone:, x:, y:)

        if existing
          # Do not replace authored outdoor spawns with a pulse ambush nameplate.
          return nil unless ambush_placement?(existing)

          existing.update!(
            npc_template: template,
            npc_key: template.npc_key,
            npc_role: "hostile",
            level: template.level,
            defeated_at: nil,
            respawns_at: nil,
            metadata: ambush_metadata(existing.metadata.to_h)
          )
          return existing
        end

        TileNpc.create!(
          npc_template: template,
          zone:,
          x:,
          y:,
          npc_key: template.npc_key,
          npc_role: "hostile",
          level: template.level,
          metadata: ambush_metadata
        )
      end

      def ambush_placement?(tile_npc)
        meta = tile_npc.metadata.to_h
        tile_npc.npc_key.to_s.start_with?("ashen_ambush_") ||
          meta["source"].to_s == "world_live_ambush" ||
          meta["ambush_label"].present?
      end

      def ambush_metadata(base = {})
        base.merge(
          "personal_instance" => true,
          "active" => true,
          "source" => "world_live_ambush",
          "ambush_label" => npc_label,
          "respawn_seconds" => 0
        )
      end

      def clear_ambush!(tile_npc)
        return unless tile_npc
        return unless ambush_placement?(tile_npc)

        tile_npc.destroy!
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
