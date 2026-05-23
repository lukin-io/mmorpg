# frozen_string_literal: true

module Game
  module World
    # ArenaNpcConfig loads captured Neverlands arena NPC definitions.
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

        # Return the captured NPC for a room. There is no generic weighting or
        # tier selection until captured source behavior requires it.
        #
        # @return [Hash, nil] selected NPC configuration or nil if none available
        def sample_npc(room_slug)
          for_room(room_slug).first
        end

        # Find a specific NPC by key across all sections
        #
        # @param key [String, Symbol] the NPC key
        # @return [Hash, nil] NPC configuration or nil if not found
        def find_npc(key)
          return nil if key.blank?

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

        # Extract explicit stats from NPC config.
        #
        # @return [Hash] stats hash with attack, defense, agility, hp
        def extract_stats(npc_config)
          stats = (npc_config.dig(:metadata, :stats) || {}).to_h.symbolize_keys
          stats[:attack] ||= npc_config[:damage]
          stats[:hp] ||= npc_config[:hp]

          Npc::CombatStats::STAT_KEYS.each_with_object({}) do |key, result|
            result[key] = (stats[key] || stats[key.to_s] || 0).to_i
          end.with_indifferent_access
        end
      end
    end
  end
end
