# frozen_string_literal: true

module Game
  module World
    # Expands reusable captured encounters onto eligible starter atlas cells.
    # This pure seed projection takes validated zone definitions and surveyed
    # cells, and returns ordinary NPC placement hashes. It never writes records
    # or invents a member's level/HP. Seeds own bootstrap/preservation; runtime
    # continues to read managed TileNpc records and select complete rosters.
    class StarterEncounterDistribution
      class InvalidConfigurationError < StandardError; end

      def initialize(zone_config:, cells:)
        @zone_config = zone_config
        @cells = cells
      end

      def call
        policy = zone_config[:starter_encounters]
        return [] unless policy

        validate_policy!(policy)
        occupied = Array(zone_config[:npcs]).map { |npc| npc.values_at(:x, :y) }.to_set
        profiles = policy.fetch(:profiles).map { |profile| build_profile(profile) }
        cells.filter_map do |cell|
          next if occupied.include?([cell.x, cell.y]) || !cell.passable
          next if cell.metadata.dig("atlas", "kind") == "city"

          matches = profiles.filter_map do |profile, source, samples|
            eligible = samples.select { |sample| eligible_roster?(sample, cell, policy.fetch(:atlas_names)) }
            [profile, source, eligible] if eligible.any?
          end
          invalid!("multiple profiles match cell [#{cell.x},#{cell.y}]") if matches.size > 1
          placement(cell, matches.first, policy) if matches.one?
        end
      end

      private

      attr_reader :zone_config, :cells

      def validate_policy!(policy)
        invalid!("policy must be an object") unless policy.is_a?(Hash)
        profiles = policy[:profiles]
        unless profiles.is_a?(Array) && profiles.any? && profiles.all? { |entry| entry.is_a?(Hash) && entry[:key].is_a?(String) && entry[:key].present? }
          invalid!("profiles require stable keys")
        end
        invalid!("profile keys must be unique") unless profiles.pluck(:key).uniq.size == profiles.size
        names = policy[:atlas_names]
        unless names.is_a?(Hash) && names.any? && names.values.all? { |name| name.is_a?(String) && name.present? }
          invalid!("atlas_names must map template keys to source names")
        end
        validate_windows!(policy[:passive_delay_windows])
        invalid!("a passive delay source is required") unless policy[:passive_delay_source].is_a?(String) && policy[:passive_delay_source].present?
      end

      def validate_windows!(windows)
        unless windows.is_a?(Array) && windows.any? && windows.all? { |window| window.is_a?(Hash) }
          invalid!("passive delay windows must be nonempty objects")
        end
        windows.each do |window|
          minimum, maximum = window.values_at(:min_seconds, :max_seconds)
          unless minimum.is_a?(Integer) && minimum.positive? && maximum.is_a?(Integer) && maximum.between?(minimum, TileNpc::MAX_PASSIVE_DELAY_SECONDS)
            invalid!("passive delay bounds must be positive ordered integers")
          end
        end
      end

      def build_profile(profile)
        source = Array(zone_config[:npcs]).find { |npc| npc[:key].to_s == profile[:source_npc_key].to_s }
        invalid!("profile #{profile[:key]} references an unknown captured NPC") unless source
        samples = source.dig(:metadata, :encounter_rosters)
        samples = [fixed_roster(source)] unless samples.present?
        samples.each do |sample|
          sample.fetch(:members).each do |member|
            unless member[:level].is_a?(Integer) && member[:level] >= 0 && member[:hp].is_a?(Integer) && member[:hp].positive?
              invalid!("profiles require captured exact member levels and positive HP; ranges are not reusable evidence")
            end
          end
        end
        [profile, source, samples]
      end

      def fixed_roster(source)
        metadata = source.fetch(:metadata, {})
        count = metadata.fetch(:encounter_count, 1)
        invalid!("captured fixed encounter count is unsupported") unless count.is_a?(Integer) && count.between?(1, TileNpc::MAX_ENCOUNTER_SIZE)
        {
          key: "#{source.fetch(:key)}_captured_fixed",
          encounter_experience_reward: metadata.fetch(:encounter_experience_reward, source[:xp]),
          trauma_percent: metadata.fetch(:trauma_percent, 30),
          members: Array.new(count) { {npc_key: source.fetch(:key), level: source[:level], hp: source[:hp]} }
        }.compact
      end

      def eligible_roster?(sample, cell, names)
        annotations = cell.metadata.dig("atlas", "npc_annotations")
        sample.fetch(:members).all? do |member|
          name = names[member.fetch(:npc_key).to_sym]
          invalid!("missing atlas name for #{member.fetch(:npc_key)}") unless name
          annotations.any? do |annotation|
            annotation.fetch("name") == name &&
              (annotation.fetch("min_level")..annotation.fetch("max_level")).cover?(member.fetch(:level))
          end
        end
      end

      def placement(cell, match, policy)
        profile, source, samples = match
        metadata = source.fetch(:metadata, {}).except(:encounter_count)
        source.deep_dup.merge(
          x: cell.x, y: cell.y,
          metadata: metadata.merge(
            source_map: cell.metadata.fetch("source_map"),
            source_coordinates: cell.metadata.fetch("source_coordinates"),
            source_location: cell.metadata.dig("atlas", "label"),
            source_observation: "2026-09-09_starter_atlas",
            source_capture_scope: "atlas_eligible_captured_roster_reuse",
            roster_source_map: source.dig(:metadata, :source_map),
            roster_source_observation: source.dig(:metadata, :source_observation),
            atlas: cell.metadata.fetch("atlas").deep_symbolize_keys,
            seed_scope: "starter_encounter_bootstrap",
            encounter_profile: profile.fetch(:key),
            encounter_selection_mode: "observed_sample_replay",
            encounter_rosters: samples.deep_dup,
            passive_delay_windows: policy.fetch(:passive_delay_windows).deep_dup,
            passive_delay_source: policy.fetch(:passive_delay_source)
          )
        )
      end

      def invalid!(message)
        raise InvalidConfigurationError, "Starter encounters #{message}"
      end
    end
  end
end
