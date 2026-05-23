# frozen_string_literal: true

module Game
  module World
    # Loads source-backed outdoor NPC definitions by explicit zone name.
    class OutdoorNpcConfig
      CONFIG_PATH = Rails.root.join("config/gameplay/outdoor_npcs.yml")

      class << self
        def config
          @config ||= YAML.load_file(CONFIG_PATH).deep_symbolize_keys
        end

        def reload!
          @config = nil
          config
        end

        def for_zone(zone_name)
          zone_key = zone_name.to_s.parameterize(separator: "_").to_sym
          zone_config = config[zone_key]
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
      end
    end
  end
end
