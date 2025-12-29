# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Represents a combat effect (buff/debuff) that modifies stats or deals damage over time.
    #
    # Inputs:
    #   - type: Symbol - effect type (:buff, :debuff, :dot, :shield, :regen)
    #   - name: String - display name
    #   - duration: Integer - turns remaining
    #   - stat_changes: Hash - stat modifiers { strength: 5, defense: -3 }
    #   - damage_per_turn: Integer - DOT damage (for poison, burn, etc.)
    #   - heal_per_turn: Integer - HOT healing (for regen effects)
    #   - damage_reduction: Float - damage reduction percentage (for shields)
    #
    # Usage:
    #   effect = Game::Combat::Effect.new(
    #     type: :dot,
    #     name: "Poison",
    #     duration: 3,
    #     damage_per_turn: 5
    #   )
    #   effect.apply_to(character_stats)
    #   effect.tick! # reduce duration
    #
    class Effect
      TYPES = %i[buff debuff dot hot shield barrier stun slow immunity].freeze

      attr_reader :type, :name, :duration, :stat_changes, :damage_per_turn,
        :heal_per_turn, :damage_reduction, :element, :source, :stacks

      attr_accessor :remaining_duration

      def initialize(
        type:,
        name:,
        duration: 1,
        stat_changes: {},
        damage_per_turn: 0,
        heal_per_turn: 0,
        damage_reduction: 0.0,
        element: "normal",
        source: nil,
        stacks: 1
      )
        @type = type.to_sym
        @name = name
        @duration = duration
        @remaining_duration = duration
        @stat_changes = stat_changes.transform_keys(&:to_sym)
        @damage_per_turn = damage_per_turn
        @heal_per_turn = heal_per_turn
        @damage_reduction = damage_reduction.clamp(0.0, 1.0)
        @element = element
        @source = source
        @stacks = stacks

        validate!
      end

      # Apply stat changes to a stat block
      #
      # @param stats [StatBlock] character stat block
      # @return [StatBlock] modified stats
      def apply_to(stats)
        return stats if expired?

        @stat_changes.each do |stat, modifier|
          current = stats.respond_to?(:get) ? stats.get(stat) : stats[stat].to_i
          modified = current + (modifier * @stacks)
          stats.respond_to?(:set) ? stats.set(stat, modified) : (stats[stat] = modified)
        end

        stats
      end

      # Remove stat changes from a stat block
      #
      # @param stats [StatBlock] character stat block
      # @return [StatBlock] restored stats
      def remove_from(stats)
        @stat_changes.each do |stat, modifier|
          current = stats.respond_to?(:get) ? stats.get(stat) : stats[stat].to_i
          restored = current - (modifier * @stacks)
          stats.respond_to?(:set) ? stats.set(stat, restored) : (stats[stat] = restored)
        end

        stats
      end

      # Process one turn of the effect
      #
      # @return [Hash] result with :damage, :heal, :expired
      def tick!
        result = {damage: 0, heal: 0, expired: false}

        # Apply DOT damage
        if damage_over_time?
          result[:damage] = @damage_per_turn * @stacks
        end

        # Apply HOT healing
        if heal_over_time?
          result[:heal] = @heal_per_turn * @stacks
        end

        # Reduce duration
        @remaining_duration -= 1
        result[:expired] = expired?

        result
      end

      # Check if effect has expired
      #
      # @return [Boolean]
      def expired?
        @remaining_duration <= 0
      end

      # Check if this is a beneficial effect
      #
      # @return [Boolean]
      def beneficial?
        %i[buff hot shield barrier immunity].include?(@type)
      end

      # Check if this is a harmful effect
      #
      # @return [Boolean]
      def harmful?
        %i[debuff dot stun slow].include?(@type)
      end

      # Check if this effect deals damage over time
      #
      # @return [Boolean]
      def damage_over_time?
        @type == :dot && @damage_per_turn > 0
      end

      # Check if this effect heals over time
      #
      # @return [Boolean]
      def heal_over_time?
        @type == :hot && @heal_per_turn > 0
      end

      # Check if this effect provides damage reduction
      #
      # @return [Boolean]
      def provides_shield?
        %i[shield barrier].include?(@type) && @damage_reduction > 0
      end

      # Check if this effect prevents actions
      #
      # @return [Boolean]
      def prevents_action?
        @type == :stun
      end

      # Add a stack to this effect
      #
      # @param max_stacks [Integer] maximum stacks allowed
      # @return [Integer] new stack count
      def add_stack(max_stacks: 5)
        @stacks = [@stacks + 1, max_stacks].min
        @remaining_duration = @duration # Refresh duration
        @stacks
      end

      # Convert to hash for JSON storage
      #
      # @return [Hash]
      def to_h
        {
          "type" => @type.to_s,
          "name" => @name,
          "duration" => @duration,
          "remaining_duration" => @remaining_duration,
          "stat_changes" => @stat_changes.transform_keys(&:to_s),
          "damage_per_turn" => @damage_per_turn,
          "heal_per_turn" => @heal_per_turn,
          "damage_reduction" => @damage_reduction,
          "element" => @element,
          "source" => @source,
          "stacks" => @stacks
        }
      end

      # Create from hash (JSON deserialization)
      #
      # @param hash [Hash] serialized effect
      # @return [Effect]
      def self.from_h(hash)
        effect = new(
          type: hash["type"],
          name: hash["name"],
          duration: hash["duration"],
          stat_changes: hash["stat_changes"] || {},
          damage_per_turn: hash["damage_per_turn"] || 0,
          heal_per_turn: hash["heal_per_turn"] || 0,
          damage_reduction: hash["damage_reduction"] || 0.0,
          element: hash["element"] || "normal",
          source: hash["source"],
          stacks: hash["stacks"] || 1
        )
        effect.remaining_duration = hash["remaining_duration"] || hash["duration"]
        effect
      end

      # Display string for combat log
      #
      # @return [String]
      def to_s
        parts = [@name]
        parts << "(#{@stacks} stacks)" if @stacks > 1
        parts << "[#{@remaining_duration} turns]"
        parts.join(" ")
      end

      private

      def validate!
        raise ArgumentError, "Invalid effect type: #{@type}" unless TYPES.include?(@type)
        raise ArgumentError, "Duration must be positive" if @duration <= 0
        raise ArgumentError, "Name is required" if @name.blank?
      end
    end
  end
end
