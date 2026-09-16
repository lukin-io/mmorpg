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
            validate_template_levels!(parsed)
            validate_combat_content!(parsed)
            validate_encounter_entries!(parsed)
            validate_encounter_presets!(parsed)
            expand_starter_encounters!(parsed)
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

        # Returns an independent copy of a globally keyed observed encounter,
        # or nil when absent. Its :metadata can be explicitly applied to an
        # authorized TileNpc through the existing content editor/persistence
        # path. Lookup does not place NPCs, select a roster, or start a fight.
        def find_encounter_preset(key)
          config.each_value do |zone_config|
            preset = Array(zone_config[:encounter_presets]).find { |entry| entry[:key].to_s == key.to_s }
            return preset.deep_dup if preset
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

        # Expands only seed inputs. Runtime NPC reads never consult this catalog.
        def expand_starter_encounters!(parsed)
          parsed.each_value do |zone_config|
            next unless zone_config[:starter_encounters]

            catalog = StarterCellCatalog.default
            unless zone_config[:zone_name] == catalog.zone_name
              raise InvalidConfigurationError, "Starter encounters must use the surveyed zone"
            end
            zone_config[:starter_npcs] = StarterEncounterDistribution.new(zone_config:, cells: catalog.cells).call
            zone_config[:starter_npcs].concat(calibrated_habitats(zone_config, parsed, catalog))
          end
        rescue StarterEncounterDistribution::InvalidConfigurationError => error
          raise InvalidConfigurationError, error.message
        end

        # These are local MVP placements of captured stronger rosters, not
        # claims about missing Neverlands coordinates. Existing managed cells
        # remain protected by StarterEncounterBootstrap.
        def calibrated_habitats(zone_config, parsed, catalog)
          presets = parsed.values.flat_map { |zone| Array(zone[:encounter_presets]) }.index_by { |preset| preset[:key] }
          Array(zone_config[:calibrated_habitats]).map do |habitat|
            cell = catalog.at(habitat.fetch(:x), habitat.fetch(:y))
            raise InvalidConfigurationError, "Calibrated habitat must be passable and remote" unless cell&.passable &&
              [[6, 8], [11, 9]].all? { |x, y| (cell.x - x).abs + (cell.y - y).abs >= 8 }

            samples = habitat.fetch(:preset_keys).flat_map do |key|
              presets.fetch(key).fetch(:metadata).fetch(:encounter_rosters)
            end
            source = template_entries(zone_config).find { |npc| npc[:key].to_s == samples.first.fetch(:members).first.fetch(:npc_key).to_s }
            raise InvalidConfigurationError, "Unknown habitat template" unless source

            source.deep_dup.merge(x: cell.x, y: cell.y, metadata: source.fetch(:metadata, {}).merge(
              active: true, combat_readiness: "calibrated_v1", calibrated_loot: true,
              source_map: cell.metadata.fetch("source_map"), source_coordinates: cell.metadata.fetch("source_coordinates"),
              seed_scope: "starter_encounter_bootstrap", encounter_profile: "stronger_calibrated_v1",
              encounter_rosters: samples, encounter_selection_mode: "observed_sample_replay",
              passive_delay_windows: [{min_seconds: 60, max_seconds: 360}],
              passive_delay_source: "calibrated_2026-09-12"))
          end
        rescue KeyError => error
          raise InvalidConfigurationError, "Invalid calibrated habitat: #{error.message}"
        end

        def validate_template_levels!(parsed)
          parsed.each_value do |zone_config|
            template_entries(zone_config).each do |npc|
              next unless npc.key?(:level)
              next if npc[:level].is_a?(Integer) && npc[:level] >= 0

              raise InvalidConfigurationError,
                "#{CONFIG_PATH}: NPC #{npc[:key] || 'unknown'} level must be a non-negative integer"
            end
          end
        end

        def validate_combat_content!(parsed)
          parsed.each_value do |zone_config|
            template_entries(zone_config).each do |npc|
              errors = NpcTemplate.combat_content_errors(npc.fetch(:metadata, {}).deep_stringify_keys)
              next if errors.empty?

              raise InvalidConfigurationError, "#{CONFIG_PATH}: NPC #{npc[:key]} #{errors.join('; ')}"
            end
          end
        end

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
          template_keys = configured_template_keys(parsed)

          parsed.each_value do |zone_config|
            template_entries(zone_config).each do |npc|
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

        def validate_encounter_presets!(parsed)
          template_keys = configured_template_keys(parsed)
          seen_keys = Set.new
          parsed.each_value do |zone_config|
            next unless zone_config.key?(:encounter_presets)

            presets = zone_config[:encounter_presets]
            unless presets.is_a?(Array)
              raise InvalidConfigurationError, "#{CONFIG_PATH}: encounter presets must be an array"
            end

            presets.each do |preset|
              unless preset.is_a?(Hash) && preset[:key].is_a?(String) && preset[:key].present?
                raise InvalidConfigurationError, "#{CONFIG_PATH}: encounter preset key must be a non-empty string"
              end
              unless seen_keys.add?(preset[:key])
                raise InvalidConfigurationError, "#{CONFIG_PATH}: duplicate encounter preset key #{preset[:key]}"
              end
              metadata = preset[:metadata]
              unless metadata.is_a?(Hash) && metadata.key?(:encounter_rosters)
                raise InvalidConfigurationError, "#{CONFIG_PATH}: encounter preset #{preset[:key]} requires encounter_rosters metadata"
              end

              errors = TileNpc.encounter_policy_errors(metadata.deep_stringify_keys)
              if errors.any?
                raise InvalidConfigurationError, "#{CONFIG_PATH}: encounter preset #{preset[:key]} #{errors.join('; ')}"
              end
              validate_roster_references!(preset, metadata, template_keys)
              validate_preset_samples!(preset)
            end
          end
        end

        # The shared TileNpc policy covers ranges/weights/levels. Presets also
        # require complete captures and integer totals before templates exist
        # in the database, so validation cannot depend on persisted TileNpc rows.
        def validate_preset_samples!(preset)
          sample_keys = Set.new
          preset.fetch(:metadata).fetch(:encounter_rosters).each do |sample|
            key = sample[:key]
            unless key.is_a?(String) && key.present? && sample_keys.add?(key)
              raise InvalidConfigurationError, "#{CONFIG_PATH}: encounter preset #{preset[:key]} roster keys must be present and unique"
            end
            %i[encounter_experience_reward encounter_defeat_experience_reward].each do |field|
              next unless sample.key?(field)
              next if sample[field].is_a?(Integer) && sample[field] >= 0

              raise InvalidConfigurationError, "#{CONFIG_PATH}: encounter preset #{preset[:key]} #{field} must be a non-negative integer"
            end
            sample.fetch(:members).each do |member|
              unless member[:level].is_a?(Integer) && member[:level] >= 0 && member[:hp].is_a?(Integer) && member[:hp].positive?
                raise InvalidConfigurationError, "#{CONFIG_PATH}: encounter preset #{preset[:key]} members require exact non-negative levels and positive HP"
              end
            end
          end
        end

        def configured_template_keys(parsed)
          parsed.values.flat_map do |zone_config|
            template_entries(zone_config).map { |entry| entry[:key].to_s }
          end.to_set
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
