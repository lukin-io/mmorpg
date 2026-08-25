# frozen_string_literal: true

module Game
  module World
    # Loads source-backed outdoor NPC definitions by explicit zone name.
    class OutdoorNpcConfig
      class InvalidConfigurationError < StandardError; end

      CONFIG_PATH = Rails.root.join("config/gameplay/outdoor_npcs.yml")

      class << self
        def config
          @config ||= begin
            parsed = YAML.load_file(CONFIG_PATH).deep_symbolize_keys
            validate_loot_entries!(parsed)
            parsed
          end
        end

        def reload!
          @config = nil
          config
        end

        def for_zone(zone_name)
          zone_config = config.values.find { |entry| entry[:zone_name] == zone_name.to_s }
          zone_config ||= config[zone_name.to_s.parameterize(separator: "_").to_sym]
          return [] unless zone_config

          zone_config[:npcs] || []
        end

        def has_npcs?(zone_name)
          for_zone(zone_name).any?
        end

        def source_npc_for_zone(zone_name)
          for_zone(zone_name).first
        end

        def source_npc_for_tile(zone_name, x, y)
          for_zone(zone_name).find do |npc|
            npc[:x].to_i == x.to_i && npc[:y].to_i == y.to_i
          end
        end

        def find_npc(key)
          config.each_value do |zone_config|
            npc = Array(zone_config[:npcs]).find { |entry| entry[:key] == key.to_sym }
            return npc if npc
          end
          nil
        end

        def all_npcs
          config.flat_map { |_, zone_config| zone_config[:npcs] || [] }.uniq { |entry| entry[:key] }
        end

        private

        def validate_loot_entries!(parsed)
          parsed.each_value do |zone_config|
            Array(zone_config[:npcs]).each do |npc|
              entries = npc[:loot_table] || npc[:loot] || []
              Array(entries).each_with_index do |entry, index|
                Game::LootEntry.new(entry)
              rescue Game::LootEntry::InvalidError => e
                raise InvalidConfigurationError,
                  "#{CONFIG_PATH}: NPC #{npc[:key] || "unknown"} loot entry #{index}: #{e.message}"
              end
            end
          end
        end
      end
    end
  end
end
