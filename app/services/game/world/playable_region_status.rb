# frozen_string_literal: true

module Game
  module World
    # Persists the last PlayableRegionBuilder outcome for Manage confirmation.
    # Boot path (no actor) and Manage CTA both write the same cache key.
    # Also mirrors to tmp JSON so a cache miss still shows the last boot line.
    class PlayableRegionStatus
      CACHE_KEY = "ashen:playable_region:last_build"
      TTL = 30.days
      FILE_PATH = Rails.root.join("tmp/playable_region_last_build.json")

      def self.record!(result:, source:, actor_id: nil)
        payload = {
          "source" => source.to_s,
          "actor_id" => actor_id,
          "recorded_at" => Time.current.iso8601,
          "cells_created" => result.cells_created.to_i,
          "cells_updated" => result.cells_updated.to_i,
          "fortresses" => result.fortresses.to_i,
          "dungeon_npcs" => result.dungeon_npcs.to_i,
          "skipped" => result.respond_to?(:skipped) ? result.skipped.to_i : 0,
          "landmark_cells" => MapTileTemplate.where(zone: PlayableRegionBuilder.bounds[:zone]).count,
          "fortress_rows" => (defined?(WorldFortress) ? WorldFortress.count : 0)
        }
        Rails.cache.write(CACHE_KEY, payload, expires_in: TTL)
        FILE_PATH.dirname.mkpath
        FILE_PATH.write(JSON.generate(payload))
        payload
      end

      def self.read
        Rails.cache.read(CACHE_KEY) || read_file
      end

      def self.read_file
        return unless FILE_PATH.exist?

        JSON.parse(FILE_PATH.read)
      rescue JSON::ParserError
        nil
      end
      private_class_method :read_file
    end
  end
end
