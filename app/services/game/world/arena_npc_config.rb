# frozen_string_literal: true

module Game
  module World
    # ArenaNpcConfig loads and provides access to arena-specific NPC configurations.
    # Configuration is loaded from config/gameplay/arena_npcs.yml
    #
    # Purpose: Manage arena bot definitions for training fights
    #
    # Usage:
    #   ArenaNpcConfig.for_room("training")
    #   # => [{key: "arena_training_dummy", role: "arena_bot", ...}, ...]
    #
    #   ArenaNpcConfig.sample_npc("training", difficulty: :easy)
    #   # => {key: "arena_novice_fighter", role: "arena_bot", ...}
    #
    #   ArenaNpcConfig.find_npc("arena_training_dummy")
    #   # => {key: "arena_training_dummy", name: "Sparring Dummy", ...}
    #
    # Returns:
    #   Hash or Array of NPC configuration hashes
    #
    class ArenaNpcConfig
      CONFIG_PATH = Rails.root.join("config/gameplay/arena_npcs.yml")

      class << self
        def config
          @config ||= YAML.load_file(CONFIG_PATH).deep_symbolize_keys
        end

        def reload!
          @config = nil
          config
        end

        # Get all NPCs available for a specific arena room
        #
        # @param room_slug [String] the arena room slug (e.g., "training", "trial")
        # @return [Array<Hash>] array of NPC configurations
        def for_room(room_slug)
          room_slug = room_slug.to_sym
          room_config = config[room_slug] || config[:default]
          npcs = room_config[:npcs] || []

          # Also include NPCs from other sections that list this room
          config.each do |section_key, section_config|
            next if section_key == room_slug || section_key == :default
            next unless section_config[:npcs]

            section_config[:npcs].each do |npc|
              arena_rooms = npc.dig(:metadata, :arena_rooms) || []
              npcs << npc if arena_rooms.include?(room_slug.to_s)
            end
          end

          npcs.uniq { |n| n[:key] }
        end

        # Get NPCs filtered by difficulty
        #
        # @param room_slug [String] the arena room slug
        # @param difficulty [Symbol] :easy, :medium, or :hard
        # @return [Array<Hash>] filtered NPC configurations
        def for_room_by_difficulty(room_slug, difficulty)
          for_room(room_slug).select do |npc|
            npc.dig(:metadata, :difficulty)&.to_sym == difficulty.to_sym
          end
        end

        # Sample a random NPC from a room, optionally filtered by difficulty
        #
        # @param room_slug [String] the arena room slug
        # @param difficulty [Symbol, nil] optional difficulty filter
        # @param rng [Random] random number generator for determinism
        # @return [Hash, nil] selected NPC configuration or nil if none available
        def sample_npc(room_slug, difficulty: nil, rng: Random.new)
          npcs = if difficulty
            for_room_by_difficulty(room_slug, difficulty)
          else
            for_room(room_slug)
          end

          return nil if npcs.empty?

          # Weighted random selection based on spawn_chance
          total_weight = npcs.sum { |n| n[:spawn_chance] || 1 }
          roll = rng.rand(total_weight)

          cumulative = 0
          npcs.each do |npc|
            cumulative += npc[:spawn_chance] || 1
            return npc if roll < cumulative
          end

          # Fallback to first NPC
          npcs.first
        end

        # Find a specific NPC by key across all sections
        #
        # @param key [String, Symbol] the NPC key
        # @return [Hash, nil] NPC configuration or nil if not found
        def find_npc(key)
          key = key.to_sym
          config.each_value do |section_config|
            next unless section_config[:npcs]

            npc = section_config[:npcs].find { |n| n[:key]&.to_sym == key }
            return npc if npc
          end
          nil
        end

        # Check if a room has any NPCs available
        #
        # @param room_slug [String] the arena room slug
        # @return [Boolean] true if NPCs are available
        def has_npcs?(room_slug)
          for_room(room_slug).any?
        end

        # Get all NPC keys for a room
        #
        # @param room_slug [String] the arena room slug
        # @return [Array<Symbol>] array of NPC keys
        def npc_keys(room_slug)
          for_room(room_slug).map { |n| n[:key]&.to_sym }.compact
        end

        # Get all unique NPCs across all sections
        #
        # @return [Array<Hash>] all NPC configurations
        def all_npcs
          config.flat_map { |_, section| section[:npcs] || [] }.uniq { |n| n[:key] }
        end

        # Get all NPCs with a specific AI behavior
        #
        # @param behavior [String, Symbol] the AI behavior type
        # @return [Array<Hash>] NPCs with that behavior
        def by_ai_behavior(behavior)
          all_npcs.select do |npc|
            npc.dig(:metadata, :ai_behavior)&.to_sym == behavior.to_sym
          end
        end

        # Get difficulty descriptions for UI
        #
        # @return [Hash] difficulty level descriptions
        def difficulty_info
          {
            easy: {emoji: "⭐", label: "Easy", description: "For beginners learning combat"},
            medium: {emoji: "⭐⭐", label: "Medium", description: "Balanced challenge"},
            hard: {emoji: "⭐⭐⭐", label: "Hard", description: "For experienced fighters"}
          }
        end

        # Extract stats from NPC config (following PveEncounterService pattern)
        #
        # @param npc_config [Hash] the NPC configuration hash
        # @return [Hash] stats hash with attack, defense, agility, hp
        def extract_stats(npc_config)
          metadata_stats = npc_config.dig(:metadata, :stats)

          if metadata_stats.present?
            metadata_stats.with_indifferent_access
          else
            level = npc_config[:level] || 1
            {
              attack: npc_config[:damage] || (level * 3 + 5),
              defense: level * 2 + 3,
              agility: level + 5,
              hp: npc_config[:hp] || (level * 10 + 20),
              crit_chance: npc_config.dig(:metadata, :stats, :crit_chance) || 10
            }.with_indifferent_access
          end
        end
      end
    end
  end
end
