# frozen_string_literal: true

require "yaml"

module Game
  module Combat
    # Shared accessors for the Neverlands-style combat action catalog.
    module ActionCatalog
      DEFAULT_AP_PER_TURN = 80
      BODY_PARTS = %w[head torso stomach legs].freeze

      STANDARD_BLOCKS = {
        %w[head] => {key: "head_block", name: "Блок головы", action_cost: 35},
        %w[head torso] => {key: "head_torso_block", name: "Блок головы и корпуса", action_cost: 50},
        %w[head stomach] => {key: "head_stomach_block", name: "Блок головы и живота", action_cost: 60},
        %w[torso] => {key: "torso_block", name: "Блок корпуса", action_cost: 30},
        %w[torso stomach] => {key: "torso_stomach_block", name: "Блок корпуса и живота", action_cost: 50},
        %w[torso legs] => {key: "torso_legs_block", name: "Блок корпуса и ног", action_cost: 60},
        %w[stomach] => {key: "stomach_block", name: "Блок живота", action_cost: 30},
        %w[stomach legs] => {key: "stomach_legs_block", name: "Блок живота и ног", action_cost: 50},
        %w[legs] => {key: "legs_block", name: "Блок ног", action_cost: 35},
        %w[head legs] => {key: "legs_head_block", name: "Блок ног и головы", action_cost: 80}
      }.freeze

      SHIELD_BLOCKS = {
        %w[head] => {key: "shield_head_block", name: "Блок щитом: голова", action_cost: 45},
        %w[torso] => {key: "shield_torso_block", name: "Блок щитом: корпус", action_cost: 40},
        %w[stomach] => {key: "shield_stomach_block", name: "Блок щитом: живот", action_cost: 40},
        %w[legs] => {key: "shield_legs_block", name: "Блок щитом: ноги", action_cost: 45},
        %w[head torso] => {key: "shield_head_torso_block", name: "Блок щитом: голова и корпус", action_cost: 65},
        %w[torso stomach] => {key: "shield_torso_stomach_block", name: "Блок щитом: корпус и живот", action_cost: 60},
        %w[stomach legs] => {key: "shield_stomach_legs_block", name: "Блок щитом: живот и ноги", action_cost: 65},
        %w[head torso stomach legs] => {key: "shield_full_block", name: "Полный блок щитом", action_cost: 100}
      }.freeze

      MAGIC_BLOCKS = {
        %w[head torso stomach legs] => [
          {key: "magic_shield", name: "Магический щит", action_cost: 45, mana_cost: 20},
          {key: "rainbow_barrier", name: "Радужный барьер", action_cost: 60, mana_cost: 40},
          {key: "crystal_sphere", name: "Кристальная сфера", action_cost: 90, mana_cost: 65}
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
            "body_parts" => body_parts_for_block_key(entry[:key])
          }
        end
      end

      def shield_blocks_config
        SHIELD_BLOCKS.values.index_by { |entry| entry[:key] }.transform_values do |entry|
          {
            "key" => entry[:key],
            "name" => entry[:name],
            "action_cost" => entry[:action_cost],
            "body_parts" => body_parts_for_shield_block_key(entry[:key]),
            "block_table" => "shield"
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
              "block_table" => "magic"
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

      def body_parts_for_shield_block_key(key)
        SHIELD_BLOCKS.find { |_parts, config| config[:key] == key }&.first || []
      end

      def canonical_parts(parts)
        Array(parts).map(&:to_s).reject(&:blank?).sort_by { |part| BODY_PARTS.index(part) || BODY_PARTS.length }
      end
    end
  end
end
