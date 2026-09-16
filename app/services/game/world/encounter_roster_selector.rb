# frozen_string_literal: true

module Game
  module World
    # Chooses one captured roster sample for a persisted wilderness encounter.
    #
    # Inputs:
    # - tile_npc: the exact-cell encounter anchor and its seed-materialized
    #   roster samples;
    # - rng: the server-owned random source used only when several samples exist.
    # - max_members: authoritative player-level ceiling supplied by StartNpcFight;
    #   defaults to the content capacity for standalone catalog inspection.
    #
    # Returns a Selection containing ordered NPC members and the captured
    # fight-level XP/risk values. Missing templates or invalid persisted data
    # fail closed before a match is created.
    class EncounterRosterSelector
      class InvalidRosterError < StandardError; end
      class NoEligibleRosterError < InvalidRosterError; end

      Member = Struct.new(:npc_template, :level, :max_hp, :metadata, keyword_init: true)
      Selection = Struct.new(
        :sample_key,
        :members,
        :experience_reward,
        :defeat_experience_reward,
        :trauma_percent,
        keyword_init: true
      )

      def initialize(tile_npc:, rng: Random.new, max_members: TileNpc::MAX_ENCOUNTER_SIZE)
        @tile_npc = tile_npc
        @rng = rng
        @max_members = max_members
      end

      def call
        samples = tile_npc.encounter_roster_samples
        return fixed_selection if samples.empty?

        weights = sample_weights(samples)
        eligible = samples.each_index.select do |index|
          sample = normalized_hash!(samples[index], "NPC encounter roster is not documented.")
          members = sample["members"]
          raise InvalidRosterError, "NPC encounter roster members are not documented." unless members.is_a?(Array)

          validate_member_count!(members.size)
          members.size <= max_members
        end
        raise NoEligibleRosterError, "No complete NPC group is available for this level." if eligible.empty?

        index = eligible.fetch(sample_index(eligible.map { |candidate| weights.fetch(candidate) }))
        build_selection(samples.fetch(index))
      end

      private

      attr_reader :tile_npc, :rng, :max_members

      def sample_weights(samples)
        unless samples.size.between?(1, TileNpc::MAX_ROSTER_SAMPLES)
          raise InvalidRosterError, "NPC encounter roster count is unsupported."
        end
        samples.map do |sample|
          value = normalized_hash!(sample, "NPC encounter roster is not documented.").fetch("weight", 1)
          unless value.is_a?(Integer) && value.between?(1, TileNpc::MAX_ROSTER_WEIGHT)
            raise InvalidRosterError, "NPC encounter roster weight is unsupported."
          end
          value
        end
      end

      def sample_index(weights)
        return 0 if weights.one?

        ticket = rng.rand(weights.sum)
        weights.each_with_index do |weight, index|
          return index if ticket < weight

          ticket -= weight
        end
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
          defeat_experience_reward: optional_non_negative_integer(sample, "encounter_defeat_experience_reward"),
          trauma_percent: optional_percent(sample, "trauma_percent") || 30
        )
      end

      def fixed_selection
        count = tile_npc.encounter_size
        validate_member_count!(count)
        if count > max_members
          raise NoEligibleRosterError, "No complete NPC group is available for this level."
        end
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
          defeat_experience_reward: optional_non_negative_integer(tile_npc.metadata.to_h, "encounter_defeat_experience_reward"),
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
        return if members.all? { |member| non_negative_level(member.level) && member.max_hp.to_i.positive? }

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

      # A range is an explicit authoring policy, never an inferred source
      # probability. Its HP must be supplied; level does not invent combat stats.
      def member_level(member, fallback)
        unless member.key?("level_min") || member.key?("level_max")
          return non_negative_level(member.fetch("level", fallback)) ||
            raise(InvalidRosterError, "NPC combat parameters are not documented.")
        end

        minimum = member["level_min"]
        maximum = member["level_max"]
        if TileNpc.member_level_range_errors(member).any?
          raise InvalidRosterError, "NPC encounter level range is not documented."
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

        value = data[key]
        return value if value.is_a?(Integer) && value >= 0

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
