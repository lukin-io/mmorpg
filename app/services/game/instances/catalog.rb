# frozen_string_literal: true

module Game
  module Instances
    # Lists dungeon/raid catalog rows for the player Instances tab.
    class Catalog
      Entry = Struct.new(:id, :kind, :name, :attempts, :enemy_count, :first_enemy, keyword_init: true)

      def self.dungeons
        rows_for("dungeon")
      end

      def self.raids
        rows_for("raid")
      end

      def self.all
        dungeons + raids
      end

      def self.find(kind:, id:)
        all.find { |row| row.kind == kind.to_s && row.id == id.to_s }
      end

      def self.rows_for(kind)
        payload = kind.to_s == "raid" ? Game::Catalog::AshenVeilFiles.raids : Game::Catalog::AshenVeilFiles.dungeons
        key = kind.to_s == "raid" ? "raids" : "dungeons"
        Array(payload[key]).map do |raw|
          enemies = if kind.to_s == "raid"
            Array(raw["encounters"]).map { |e| e["enemyId"] }
          else
            Array(raw["rooms"]).map { |e| e["enemyId"] }
          end.compact
          Entry.new(
            id: raw["id"].to_s,
            kind: kind.to_s,
            name: raw.dig("name", "ru-RU").presence || raw.dig("name", "en-US").presence || raw["id"].to_s,
            attempts: raw["dailyAttempts"].to_i,
            enemy_count: enemies.size,
            first_enemy: enemies.first.to_s
          )
        end
      end
      private_class_method :rows_for
    end
  end
end
