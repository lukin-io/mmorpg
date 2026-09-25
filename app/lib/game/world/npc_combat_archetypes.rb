# frozen_string_literal: true

require "yaml"
require "zlib"

module Game
  module World
    # Loads Mist-guided soft-release NPC combat archetype multipliers.
    module NpcCombatArchetypes
      CONFIG_PATH = Rails.root.join("config/gameplay/npc_combat_archetypes.yml")
      KEYS = %w[tank evader critter mage].freeze

      module_function

      def config
        @config ||= YAML.safe_load_file(CONFIG_PATH, aliases: false)
      end

      def reload!
        @config = nil
        config
      end

      def archetype_for(npc_template)
        meta = npc_template.metadata.to_h
        explicit = meta["combat_archetype"].presence || meta["archetype"].presence
        return explicit.to_s if KEYS.include?(explicit.to_s)

        shore = config.fetch("shore_keys", {})[npc_template.npc_key.to_s]
        return shore if KEYS.include?(shore.to_s)

        case meta["ashen_role"].to_s
        when "boss" then "mage"
        when "elite" then "critter"
        else
          # Stable rotation by key so farm bots stay diverse without RNG drift.
          KEYS[Zlib.crc32(npc_template.npc_key.to_s) % KEYS.length]
        end
      end

      def profile(archetype)
        row = config.fetch("archetypes").fetch(archetype.to_s)
        row.merge("key" => archetype.to_s)
      end
    end
  end
end
