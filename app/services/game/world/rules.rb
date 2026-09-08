# frozen_string_literal: true

require "yaml"

module Game
  module World
    # Validates immutable numeric World parameters loaded from trusted YAML.
    # .default caches the normal catalog; .reload! replaces it only after a
    # successful validation. .new(data:) supplies an isolated ruleset to a
    # calculator or workflow without IO. Rules contain no executable formulas,
    # rewards, NPC selection probabilities, or client-authoritative values.
    class Rules
      class InvalidConfigurationError < StandardError; end

      CONFIG_PATH = Rails.root.join("config/gameplay/world_rules.yml")

      class << self
        def default
          @default ||= load
        end

        def reload!
          @default = load
        end

        def load(path: CONFIG_PATH)
          new(data: YAML.safe_load_file(path, aliases: false))
        rescue Psych::Exception, SystemCallError => error
          raise InvalidConfigurationError, "World rules could not be loaded: #{error.message}"
        end
      end

      attr_reader :movement, :fatigue

      def initialize(data:)
        validate_keys!(data, %w[movement fatigue local_actions presence], "world")
        @movement = data.fetch("movement").deep_dup
        @fatigue = data.fetch("fatigue").deep_dup
        @local_actions = data.fetch("local_actions").deep_dup
        @presence = data.fetch("presence").deep_dup
        validate_movement!
        validate_fatigue!
        validate_actions!
        validate_keys!(presence, %w[freshness_seconds], "presence")
        validate_integer!(presence, "freshness_seconds", 1..86_400, "presence")
        [movement, fatigue, presence].each(&:freeze)
        local_actions.each_value(&:freeze)
        local_actions.freeze
        freeze
      end

      def local_action_duration_seconds(type)
        local_actions.fetch(type.to_s).fetch("duration_seconds")
      end

      def drinking_fatigue_recovery_points(nature_child: false)
        key = nature_child ? "nature_child_recovery_points" : "fatigue_recovery_points"
        local_actions.fetch("drinking").fetch(key)
      end

      def movement_fatigue_gain(rng:)
        rng.rand(fatigue.fetch("movement_gain_min")..fatigue.fetch("movement_gain_max"))
      end

      def presence_freshness_seconds
        presence.fetch("freshness_seconds")
      end

      private

      attr_reader :local_actions, :presence

      def validate_movement!
        validate_keys!(movement, %w[base_seconds minimum_seconds wanderer_max_level wanderer_max_reduction_seconds], "movement")
        validate_integer!(movement, "base_seconds", 1..3600, "movement")
        validate_integer!(movement, "minimum_seconds", 1..movement.fetch("base_seconds"), "movement")
        validate_integer!(movement, "wanderer_max_level", 1..100, "movement")
        maximum_reduction = movement.fetch("base_seconds") - movement.fetch("minimum_seconds")
        validate_integer!(movement, "wanderer_max_reduction_seconds", 0..maximum_reduction, "movement")
      end

      def validate_fatigue!
        validate_keys!(fatigue, %w[recovery_interval_seconds recovery_points outdoor_action_lock_percent movement_gain_min movement_gain_max], "fatigue")
        validate_integer!(fatigue, "recovery_interval_seconds", 1..86_400, "fatigue")
        validate_integer!(fatigue, "recovery_points", 1..100, "fatigue")
        validate_integer!(fatigue, "outdoor_action_lock_percent", 1..100, "fatigue")
        validate_integer!(fatigue, "movement_gain_min", 0..100, "fatigue")
        validate_integer!(fatigue, "movement_gain_max", fatigue.fetch("movement_gain_min")..100, "fatigue")
      end

      def validate_actions!
        validate_keys!(local_actions, %w[resource_search fishing drinking], "local_actions")
        %w[resource_search fishing].each do |type|
          parameters = local_actions.fetch(type)
          validate_keys!(parameters, %w[duration_seconds], "local_actions.#{type}")
          validate_integer!(parameters, "duration_seconds", 1..3600, "local_actions.#{type}")
        end

        drinking = local_actions.fetch("drinking")
        validate_keys!(drinking, %w[duration_seconds fatigue_recovery_points nature_child_recovery_points], "local_actions.drinking")
        validate_integer!(drinking, "duration_seconds", 1..3600, "local_actions.drinking")
        validate_integer!(drinking, "fatigue_recovery_points", 1..100, "local_actions.drinking")
        validate_integer!(drinking, "nature_child_recovery_points", 1..100, "local_actions.drinking")
      end

      def validate_keys!(value, keys, path)
        return if value.is_a?(Hash) && value.keys.all? { |key| key.is_a?(String) } && value.keys.sort == keys.sort

        raise InvalidConfigurationError, "World rules #{path} must contain exactly: #{keys.join(', ')}"
      end

      def validate_integer!(section, key, range, path)
        value = section.fetch(key)
        return if value.is_a?(Integer) && range.cover?(value)

        raise InvalidConfigurationError, "World rules #{path}.#{key} must be an integer within #{range}"
      end
    end
  end
end
