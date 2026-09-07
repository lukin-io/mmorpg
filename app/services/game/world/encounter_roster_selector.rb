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

      def initialize(tile_npc:, rng: Random.new)
        @tile_npc = tile_npc
        @rng = rng
      end

      def call
        samples = tile_npc.encounter_roster_samples
        return fixed_selection if samples.empty?

        build_selection(samples.fetch(sample_index(samples)))
      end

      private

      attr_reader :tile_npc, :rng

      def sample_index(samples)
        return 0 if samples.one?

        rng.rand(samples.length)
      end

      def build_selection(raw_sample)
        sample = normalized_hash!(raw_sample, "NPC encounter roster is not documented.")
        raw_members = sample["members"]
        unless raw_members.is_a?(Array)
          raise InvalidRosterError, "NPC encounter roster members are not documented."
        end
        validate_member_count!(raw_members.size)
        normalized_members = raw_members.map do |raw_member|
          normalized_hash!(raw_member, "NPC encounter roster member is not documented.")
        end
        templates = templates_by_key(normalized_members)
        members = normalized_members.map do |member|
          npc_key = member["npc_key"].to_s
          template = templates[npc_key]
          raise InvalidRosterError, "NPC template #{npc_key.inspect} is unavailable." unless template

          member_metadata = normalized_hash!(
            member.fetch("metadata", {}),
            "NPC encounter member metadata is not documented."
          )
          Member.new(
            npc_template: template,
            level: positive_member_value(member, "level", template.level),
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
        count = tile_npc.encounter_size
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
        return if members.all? { |member| member.level.to_i.positive? && member.max_hp.to_i.positive? }

        raise InvalidRosterError, "NPC combat parameters are not documented."
      end

      def validate_member_count!(count)
        return if count.between?(1, TileNpc::MAX_ENCOUNTER_SIZE)

        raise InvalidRosterError, "NPC encounter size is not supported."
      end

      def positive_member_value(member, key, fallback)
        return fallback unless member.key?(key)

        positive_integer(member[key]) || raise(InvalidRosterError, "NPC combat parameters are not documented.")
      end

      def positive_integer(value)
        parsed = Integer(value, exception: false)
        parsed if parsed&.positive?
      end

      def optional_non_negative_integer(data, key)
        return unless data.key?(key)

        parsed = Integer(data[key], exception: false)
        return parsed if parsed && parsed >= 0

        raise InvalidRosterError, "NPC encounter experience is not documented."
      end

      def optional_percent(data, key)
        return unless data.key?(key)

        parsed = Integer(data[key], exception: false)
        return parsed if parsed&.between?(0, 100)

        raise InvalidRosterError, "NPC encounter injury risk is not documented."
      end
    end
  end
end
