# frozen_string_literal: true

require "yaml"

module Game
  module Combat
    # Shared accessors for the Neverlands-style combat action catalog.
    module ActionCatalog
      DEFAULT_AP_PER_TURN = 80
      BODY_PARTS = %w[head torso stomach legs].freeze
      PHYSICAL_ATTACK_KEYS = %w[simple aimed].freeze
      PHYSICAL_BLOCK_TABLES = %w[normal shield_40 shield_70 shield_90].freeze

      STANDARD_BLOCKS = {
        %w[head] => {key: "head_block", name: "Head Block", action_cost: 35, selector_part: "head"},
        %w[head torso] => {key: "head_torso_block", name: "Head and Torso Block", action_cost: 50, selector_part: "head"},
        %w[head stomach] => {key: "head_stomach_block", name: "Head and Abdomen Block", action_cost: 60, selector_part: "head"},
        %w[torso] => {key: "torso_block", name: "Torso Block", action_cost: 30, selector_part: "torso"},
        %w[torso stomach] => {key: "torso_stomach_block", name: "Torso and Abdomen Block", action_cost: 50, selector_part: "torso"},
        %w[torso legs] => {key: "torso_legs_block", name: "Torso and Legs Block", action_cost: 60, selector_part: "torso"},
        %w[stomach] => {key: "stomach_block", name: "Abdomen Block", action_cost: 30, selector_part: "stomach"},
        %w[stomach legs] => {key: "stomach_legs_block", name: "Abdomen and Legs Block", action_cost: 50, selector_part: "stomach"},
        %w[legs] => {key: "legs_block", name: "Legs Block", action_cost: 35, selector_part: "legs"},
        %w[head legs] => {key: "legs_head_block", name: "Legs and Head Block", action_cost: 80, selector_part: "legs"}
      }.freeze

      MAGIC_BLOCKS = {
        %w[head torso stomach legs] => [
          {key: "magic_shield", name: "Magic Shield", action_cost: 45, mana_cost: 20},
          {key: "rainbow_barrier", name: "Rainbow Barrier", action_cost: 60, mana_cost: 40},
          {key: "crystal_sphere", name: "Crystal Sphere", action_cost: 90, mana_cost: 65}
        ]
      }.freeze

      module_function

      def config
        config_path = Rails.root.join("config/gameplay/combat_actions.yml")
        raise "Missing source-backed combat action catalog: #{config_path}" unless File.exist?(config_path)

        YAML.load_file(config_path)
      end

      def standard_blocks_config
        STANDARD_BLOCKS.values.index_by { |entry| entry[:key] }.transform_values do |entry|
          {
            "key" => entry[:key],
            "name" => entry[:name],
            "action_cost" => entry[:action_cost],
            "body_parts" => body_parts_for_block_key(entry[:key]),
            "block_table" => "normal",
            "selector_part" => entry[:selector_part]
          }
        end
      end

      def magic_blocks_config
        MAGIC_BLOCKS.each_with_object({}) do |(parts, entries), memo|
          entries.each do |entry|
            memo[entry[:key]] = {
              "key" => entry[:key],
              "name" => entry[:name],
              "action_cost" => entry[:action_cost],
              "mana_cost" => entry[:mana_cost],
              "body_parts" => parts,
              "block_table" => "magic",
              "selector_part" => "all"
            }
          end
        end
      end

      def action_points_per_turn(combat_config = config)
        combat_config.dig("defaults", "action_points_per_turn") || DEFAULT_AP_PER_TURN
      end

      def attack_config(action_key, combat_config = config)
        combat_config.dig("attack_types", action_key.to_s) || {}
      end

      def attack_cost(action_key, combat_config = config)
        attack_config(action_key, combat_config).fetch("action_cost", 0).to_i
      end

      def attack_damage_multiplier(action_key, combat_config = config)
        attack_config(action_key, combat_config).fetch("damage_multiplier", 1.0).to_f
      end

      def attack_hit_bonus(action_key, combat_config = config)
        attack_config(action_key, combat_config).fetch("hit_bonus", 0).to_i
      end

      def attack_mana_cost(action_key, combat_config = config)
        attack_config(action_key, combat_config).fetch("mana_cost", 0).to_i
      end

      def attack_options_for_profile(profile, combat_config = config)
        injected_keys = Array(profile.to_h["injected_attack_keys"]).map(&:to_s)

        (combat_config["attack_types"] || {}).select do |key, _attack|
          PHYSICAL_ATTACK_KEYS.include?(key.to_s) || injected_keys.include?(key.to_s)
        end
      end

      def attack_allowed_for_profile?(action_key, profile, combat_config = config)
        attack_options_for_profile(profile, combat_config).key?(action_key.to_s)
      end

      def attack_penalty(attack_count, combat_config = config)
        penalties = combat_config["attack_penalties"] || []
        penalty_entry = penalties.find { |entry| entry["attacks"].to_i == attack_count.to_i }
        penalty_entry&.dig("penalty").to_i
      end

      def block_cost(action_key: nil, body_parts: nil, combat_config: config)
        configured = block_config(action_key, combat_config)
        return configured["action_cost"].to_i if configured.present?

        standard_block_for_parts(body_parts)&.fetch(:action_cost, nil) || 0
      end

      def block_config(action_key, combat_config = config)
        return {} if action_key.blank?

        combat_config.dig("block_types", action_key.to_s) || {}
      end

      def block_options_for_profile(profile, combat_config = config)
        physical_table = normalize_block_table(profile.to_h["block_table"])
        injected_keys = Array(profile.to_h["injected_block_keys"]).map(&:to_s)

        (combat_config["block_types"] || {}).select do |key, block|
          table = block["block_table"].presence || "normal"
          table == physical_table || (table == "magic" && injected_keys.include?(key.to_s))
        end
      end

      def block_allowed_for_profile?(action_key, profile, combat_config = config)
        block_options_for_profile(profile, combat_config).key?(action_key.to_s)
      end

      def normalize_block_table(value)
        table = value.to_s
        table = "shield_#{table}" if %w[40 70 90].include?(table)
        PHYSICAL_BLOCK_TABLES.include?(table) ? table : "normal"
      end

      def magic_config(action_key, combat_config = config)
        return {} if action_key.blank?

        combat_config.dig("magic_types", action_key.to_s) || {}
      end

      def magic_cost(action_key, combat_config = config)
        magic_config(action_key, combat_config).fetch("action_cost", 0).to_i
      end

      def magic_mana_cost(action_key, combat_config = config)
        magic_config(action_key, combat_config).fetch("mana_cost", 0).to_i
      end

      def standard_block_for_parts(parts)
        STANDARD_BLOCKS[canonical_parts(parts)]
      end

      def body_part_multiplier(body_part, combat_config = config)
        combat_config.dig("body_parts", body_part.to_s, "damage_multiplier") || 1.0
      end

      def body_parts_for_block_key(key)
        STANDARD_BLOCKS.find { |_parts, config| config[:key] == key }&.first || []
      end

      def canonical_parts(parts)
        Array(parts).map(&:to_s).reject(&:blank?).sort_by { |part| BODY_PARTS.index(part) || BODY_PARTS.length }
      end
    end
  end
end
