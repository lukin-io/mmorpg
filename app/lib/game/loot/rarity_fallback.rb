# frozen_string_literal: true

module Game
  module Loot
    # Soft-release fallback rarity pools when an NPC loot table has no rarity tags.
    # Keys are existing Ashen shore/starter mats (no third-party IP).
    module RarityFallback
      CONFIG_PATH = Rails.root.join("config/gameplay/ashen_loot_rarity.yml")

      # Base percent chances before luck scaling.
      CHANCES = {
        "common" => 15.0,
        "uncommon" => 3.0,
        "rare" => 0.5
      }.freeze

      module_function

      def config
        @config ||= YAML.safe_load_file(CONFIG_PATH, aliases: false).fetch("rarity_pools")
      end

      def reload!
        @config = nil
        config
      end

      def pools
        config
      end

      def table_has_rarity_tags?(loot_table)
        Array(loot_table).any? do |entry|
          next false unless entry.is_a?(Hash)

          row = entry.with_indifferent_access
          row[:rarity].present? || row.dig(:metadata, :rarity).present?
        end
      end
    end
  end
end
