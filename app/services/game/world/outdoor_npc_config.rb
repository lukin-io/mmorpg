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
            validate_encounter_entries!(parsed)
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
            npc = template_entries(zone_config).find { |entry| entry[:key].to_s == key.to_s }
            return npc if npc
          end
          nil
        end

        def all_npcs
          config.flat_map { |_, zone_config| zone_config[:npcs] || [] }.uniq { |entry| entry[:key] }
        end

        def all_templates
          config.flat_map { |_, zone_config| template_entries(zone_config) }.uniq { |entry| entry[:key] }
        end

        private

        def validate_loot_entries!(parsed)
          parsed.each_value do |zone_config|
            template_entries(zone_config).each do |npc|
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

        def validate_encounter_entries!(parsed)
          template_keys = parsed.values.flat_map do |zone_config|
            template_entries(zone_config).map { |entry| entry[:key].to_s }
          end.to_set

          parsed.each_value do |zone_config|
            Array(zone_config[:npcs]).each do |npc|
              metadata = npc.fetch(:metadata, {}).to_h
              policy_errors = TileNpc.encounter_policy_errors(metadata.deep_stringify_keys)
              if policy_errors.any?
                raise InvalidConfigurationError,
                  "#{CONFIG_PATH}: NPC #{npc[:key] || 'unknown'} #{policy_errors.join('; ')}"
              end
              validate_roster_references!(npc, metadata, template_keys)
            end
          end
        end

        def validate_roster_references!(npc, metadata, template_keys)
          return unless metadata.key?(:encounter_rosters)

          samples = metadata[:encounter_rosters]
          unless samples.is_a?(Array) && samples.any?
            raise InvalidConfigurationError,
              "#{CONFIG_PATH}: NPC #{npc[:key] || 'unknown'} encounter rosters must be a non-empty array"
          end

          samples.each_with_index do |sample, sample_index|
            members = sample.is_a?(Hash) ? sample[:members] : nil
            unless members.is_a?(Array) && members.size.between?(1, TileNpc::MAX_ENCOUNTER_SIZE)
              raise InvalidConfigurationError,
                "#{CONFIG_PATH}: NPC #{npc[:key] || 'unknown'} roster #{sample_index} has invalid members"
            end

            members.each_with_index do |member, member_index|
              key = member.is_a?(Hash) ? member[:npc_key].to_s : ""
              next if key.present? && template_keys.include?(key)

              referenced_key = member[:npc_key] if member.is_a?(Hash)

              raise InvalidConfigurationError,
                "#{CONFIG_PATH}: NPC #{npc[:key] || 'unknown'} roster #{sample_index} " \
                "member #{member_index} references unknown template #{referenced_key.inspect}"
            end
          end
        end

        def template_entries(zone_config)
          Array(zone_config[:npc_templates]) + Array(zone_config[:npcs])
        end
      end
    end
  end
end
