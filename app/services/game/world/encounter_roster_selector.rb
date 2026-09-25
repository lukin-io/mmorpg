# frozen_string_literal: true

module Game
  module World
    # Chooses one captured roster sample for a persisted wilderness encounter.
    #
    # Inputs:
    # - tile_npc: the exact-cell encounter anchor and its seed-materialized
    #   roster samples;
    # - rng: the server-owned random source used only when several samples exist.
    #
    # Returns a Selection containing ordered NPC members and the captured
    # fight-level XP/risk values. Missing templates or invalid persisted data
    # fail closed before a match is created.
    class EncounterRosterSelector
      class InvalidRosterError < StandardError; end

      Member = Struct.new(:npc_template, :level, :max_hp, :metadata, keyword_init: true)
      Selection = Struct.new(
        :sample_key,
        :members,
        :experience_reward,
        :trauma_percent,
        keyword_init: true
      )

      def initialize(tile_npc:, character: nil, rng: Random.new)
        @tile_npc = tile_npc
        @character = character
        @rng = rng
      end

      def call
        samples = tile_npc.encounter_roster_samples
        return fixed_selection if samples.empty?

        build_selection(samples.fetch(sample_index(samples)))
      end

      private

      attr_reader :tile_npc, :character, :rng

      def sample_index(samples)
        unless samples.size.between?(1, TileNpc::MAX_ROSTER_SAMPLES)
          raise InvalidRosterError, I18n.t("manage.roster_count_unsupported")
        end
        weights = samples.map do |sample|
          value = normalized_hash!(sample, I18n.t("manage.roster_not_documented")).fetch("weight", 1)
          unless value.is_a?(Integer) && value.between?(1, TileNpc::MAX_ROSTER_WEIGHT)
            raise InvalidRosterError, I18n.t("manage.roster_weight_unsupported")
          end
          value
        end
        return 0 if samples.one?

        ticket = rng.rand(weights.sum)
        weights.each_with_index do |weight, index|
          return index if ticket < weight

          ticket -= weight
        end
      end

      def build_selection(raw_sample)
        sample = normalized_hash!(raw_sample, I18n.t("manage.roster_not_documented"))
        raw_members = sample["members"]
        unless raw_members.is_a?(Array)
          raise InvalidRosterError, I18n.t("manage.roster_members_not_documented")
        end
        validate_member_count!(raw_members.size)
        normalized_members = raw_members.map do |raw_member|
          normalized_hash!(raw_member, I18n.t("manage.roster_member_not_documented"))
        end
        templates = templates_by_key(normalized_members)
        members = normalized_members.map do |member|
          npc_key = member["npc_key"].to_s
          template = templates[npc_key]
          raise InvalidRosterError, I18n.t("manage.roster_template_unavailable", key: npc_key.inspect) unless template

          member_metadata = normalized_hash!(
            member.fetch("metadata", {}),
            I18n.t("manage.roster_member_metadata_not_documented")
          )
          Member.new(
            npc_template: template,
            level: member_level(member, template.level),
            max_hp: positive_member_value(member, "hp", template.health),
            metadata: member_metadata
          )
        end

        validate_members!(members)

        Selection.new(
          sample_key: sample["key"].to_s,
          members:,
          experience_reward: optional_non_negative_integer(sample, "encounter_experience_reward"),
          trauma_percent: optional_percent(sample, "trauma_percent") || 30
        )
      end

      def fixed_selection
        count = encounter_member_count
        validate_member_count!(count)
        health = [tile_npc.current_hp.to_i, tile_npc.npc_template.health.to_i].find(&:positive?)
        members = Array.new(count) do
          Member.new(
            npc_template: tile_npc.npc_template,
            level: tile_npc.level,
            max_hp: health,
            metadata: {}
          )
        end
        validate_members!(members)

        Selection.new(
          sample_key: nil,
          members:,
          experience_reward: fixed_experience_reward,
          trauma_percent: optional_percent(tile_npc.metadata.to_h, "trauma_percent") || 30
        )
      end

      def encounter_member_count
        if character && tile_npc.personal_instance?
          AggroPackSize.new(level: character.level, rng:).call
        else
          tile_npc.encounter_size
        end
      end

      def fixed_experience_reward
        metadata = tile_npc.metadata.to_h
        return optional_non_negative_integer(metadata, "encounter_experience_reward") if metadata.key?("encounter_experience_reward")

        tile_npc.npc_template.xp_reward
      end

      def templates_by_key(members)
        keys = members.map { |member| member["npc_key"].to_s }.uniq
        NpcTemplate.where(npc_key: keys).index_by(&:npc_key)
      end

      def normalized_hash!(value, message)
        raise InvalidRosterError, message unless value.is_a?(Hash)

        value.stringify_keys
      end

      def validate_members!(members)
        return if members.all? { |member| non_negative_level(member.level) && member.max_hp.to_i.positive? }

        raise InvalidRosterError, I18n.t("manage.roster_combat_params_not_documented")
      end

      def validate_member_count!(count)
        return if count.between?(1, TileNpc::MAX_ENCOUNTER_SIZE)

        raise InvalidRosterError, I18n.t("manage.roster_size_unsupported")
      end

      def positive_member_value(member, key, fallback)
        return fallback unless member.key?(key)

        positive_integer(member[key]) || raise(InvalidRosterError, I18n.t("manage.roster_combat_params_not_documented"))
      end

      # A range is an explicit authoring policy, never an inferred source
      # probability. Its HP must be supplied; level does not invent combat stats.
      def member_level(member, fallback)
        unless member.key?("level_min") || member.key?("level_max")
          return non_negative_level(member.fetch("level", fallback)) ||
            raise(InvalidRosterError, I18n.t("manage.roster_combat_params_not_documented"))
        end

        minimum = member["level_min"]
        maximum = member["level_max"]
        if TileNpc.member_level_range_errors(member).any?
          raise InvalidRosterError, I18n.t("manage.roster_level_range_not_documented")
        end

        minimum == maximum ? minimum : rng.rand(minimum..maximum)
      end

      def non_negative_level(value)
        parsed = Integer(value.to_s, exception: false)
        parsed if parsed && parsed >= 0
      end

      def positive_integer(value)
        parsed = Integer(value, exception: false)
        parsed if parsed&.positive?
      end

      def optional_non_negative_integer(data, key)
        return unless data.key?(key)

        parsed = Integer(data[key], exception: false)
        return parsed if parsed && parsed >= 0

        raise InvalidRosterError, I18n.t("manage.roster_experience_not_documented")
      end

      def optional_percent(data, key)
        return unless data.key?(key)

        parsed = Integer(data[key], exception: false)
        return parsed if parsed&.between?(0, 100)

        raise InvalidRosterError, I18n.t("manage.roster_injury_risk_not_documented")
      end
    end
  end
end
