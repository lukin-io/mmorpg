# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Validates combat turn actions against AP limits, exclusivity rules, and combat state.
    #
    # Inputs:
    #   - participant: BattleParticipant with pending actions
    #   - attacks: Array<Hash> - attack selections [{body_part:, action_key:, mana:}]
    #   - blocks: Array<Hash> - block selections [{body_part:, action_key:}]
    #   - skills: Array<Hash> - skill/magic selections [{key:, target_id:}]
    #   - config: Hash - combat configuration from combat_actions.yml
    #
    # Returns:
    #   Result struct with :valid?, :errors, :total_ap, :total_mana
    #
    # Usage:
    #   validator = Game::Combat::ActionValidator.new(participant, config)
    #   result = validator.validate(attacks: attacks, blocks: blocks, skills: [])
    #   if result.valid?
    #     # proceed with turn
    #   else
    #     # handle errors
    #   end
    #
    class ActionValidator
      Result = Struct.new(:valid?, :errors, :total_ap, :total_mana, :warnings, keyword_init: true)

      # Attack exclusivity groups - can't attack body parts from different groups
      # Based on Neverlands: head+legs combination is banned
      ATTACK_EXCLUSIVITY = {
        "diagonal_banned" => [
          %w[head legs],
          %w[legs head]
        ]
      }.freeze

      # Block rules
      MAX_BLOCKS_PER_TURN = 1
      MAX_ATTACKS_PER_TURN = 4

      def initialize(participant, config = nil)
        @participant = participant
        @config = config || load_default_config
        @errors = []
        @warnings = []
      end

      # Validate complete turn actions
      #
      # @param attacks [Array<Hash>] attack selections
      # @param blocks [Array<Hash>] block selections
      # @param skills [Array<Hash>] skill/magic selections
      # @return [Result] validation result
      def validate(attacks: [], blocks: [], skills: [])
        @errors = []
        @warnings = []

        # Validate participant can act
        validate_can_act

        # Validate attack exclusivity
        validate_attack_exclusivity(attacks)

        # Validate single block rule
        validate_block_limit(blocks)

        # Validate max attacks
        validate_attack_limit(attacks)

        # Calculate costs
        total_ap = calculate_total_ap(attacks, blocks, skills)
        total_mana = calculate_total_mana(attacks, skills)

        # Validate AP limit
        validate_ap_limit(total_ap)

        # Validate mana
        validate_mana(total_mana)

        # Validate individual actions
        validate_attacks(attacks)
        validate_blocks(blocks)
        validate_skills(skills)

        Result.new(
          valid?: @errors.empty?,
          errors: @errors,
          total_ap: total_ap,
          total_mana: total_mana,
          warnings: @warnings
        )
      end

      # Quick validation for a single attack selection
      #
      # @param body_part [String] target body part
      # @param action_key [String] attack type
      # @param existing_attacks [Array<Hash>] already selected attacks
      # @return [Hash] { valid: Boolean, error: String|nil }
      def validate_attack_selection(body_part:, action_key:, existing_attacks: [])
        # Check exclusivity with existing attacks
        selected_parts = existing_attacks.map { |a| a[:body_part] || a["body_part"] }

        ATTACK_EXCLUSIVITY["diagonal_banned"].each do |banned_combo|
          if selected_parts.include?(banned_combo[0]) && body_part == banned_combo[1]
            return {valid: false, error: "Cannot attack #{body_part} when attacking #{banned_combo[0]}"}
          end
        end

        # Check max attacks
        if existing_attacks.size >= MAX_ATTACKS_PER_TURN
          return {valid: false, error: "Maximum #{MAX_ATTACKS_PER_TURN} attacks per turn"}
        end

        {valid: true, error: nil}
      end

      # Quick validation for block selection
      #
      # @param body_part [String] block body part
      # @param existing_blocks [Array<Hash>] already selected blocks
      # @return [Hash] { valid: Boolean, error: String|nil }
      def validate_block_selection(body_part:, existing_blocks: [])
        if existing_blocks.size >= MAX_BLOCKS_PER_TURN
          return {valid: false, error: "Only #{MAX_BLOCKS_PER_TURN} block allowed per turn"}
        end

        {valid: true, error: nil}
      end

      private

      def load_default_config
        config_path = Rails.root.join("config/gameplay/combat_actions.yml")
        if File.exist?(config_path)
          YAML.load_file(config_path)
        else
          default_config
        end
      end

      def default_config
        {
          "defaults" => {
            "action_points_per_turn" => 80,
            "max_mana_per_attack" => 50
          },
          "attack_penalties" => [
            {"attacks" => 0, "penalty" => 0},
            {"attacks" => 1, "penalty" => 0},
            {"attacks" => 2, "penalty" => 25},
            {"attacks" => 3, "penalty" => 75},
            {"attacks" => 4, "penalty" => 150}
          ]
        }
      end

      def validate_can_act
        return if @participant.nil?

        unless @participant.is_alive
          @errors << "You are defeated and cannot act"
        end

        if @participant.current_hp.to_i <= 0
          @errors << "You have no HP remaining"
        end
      end

      def validate_attack_exclusivity(attacks)
        return if attacks.size < 2

        body_parts = attacks.map { |a| a[:body_part] || a["body_part"] }.compact

        ATTACK_EXCLUSIVITY["diagonal_banned"].each do |banned_combo|
          if body_parts.include?(banned_combo[0]) && body_parts.include?(banned_combo[1])
            @errors << "Cannot attack #{banned_combo[0]} and #{banned_combo[1]} in the same turn"
          end
        end
      end

      def validate_block_limit(blocks)
        if blocks.size > MAX_BLOCKS_PER_TURN
          @errors << "Only #{MAX_BLOCKS_PER_TURN} block allowed per turn"
        end
      end

      def validate_attack_limit(attacks)
        if attacks.size > MAX_ATTACKS_PER_TURN
          @errors << "Maximum #{MAX_ATTACKS_PER_TURN} attacks per turn"
        end
      end

      def calculate_total_ap(attacks, blocks, skills)
        attack_cost = attacks.sum { |a| action_cost(a[:action_key] || a["action_key"], "attack_types") }
        block_cost = blocks.sum { |b| action_cost(b[:action_key] || b["action_key"], "block_types") }
        skill_cost = skills.sum { |s| action_cost(s[:key] || s["key"], "magic_types") }

        # Add multi-attack penalty
        penalty = attack_penalty(attacks.size)

        attack_cost + block_cost + skill_cost + penalty
      end

      def calculate_total_mana(attacks, skills)
        # Magic attacks can have mana cost
        attack_mana = attacks.sum do |a|
          mana = a[:mana] || a["mana"]
          mana.to_i
        end

        skill_mana = skills.sum do |s|
          key = s[:key] || s["key"]
          @config.dig("magic_types", key, "mana_cost").to_i
        end

        attack_mana + skill_mana
      end

      def validate_ap_limit(total_ap)
        max_ap = ap_limit
        if total_ap > max_ap
          @errors << "Actions exceed AP limit (#{total_ap}/#{max_ap})"
        end
      end

      def validate_mana(total_mana)
        return if @participant.nil?

        current_mp = @participant.current_mp.to_i
        if total_mana > current_mp
          @errors << "Not enough MP (need #{total_mana}, have #{current_mp})"
        end

        max_mana = @config.dig("defaults", "max_mana_per_attack") || 50
        if total_mana > max_mana
          @warnings << "High mana usage: #{total_mana}/#{max_mana}"
        end
      end

      def validate_attacks(attacks)
        attacks.each_with_index do |attack, index|
          body_part = attack[:body_part] || attack["body_part"]
          action_key = attack[:action_key] || attack["action_key"]

          unless %w[head torso stomach legs].include?(body_part)
            @errors << "Invalid body part for attack #{index + 1}: #{body_part}"
          end

          # Validate action key exists
          unless @config.dig("attack_types", action_key) || %w[simple aimed].include?(action_key)
            @warnings << "Unknown attack type: #{action_key}"
          end
        end
      end

      def validate_blocks(blocks)
        blocks.each_with_index do |block, index|
          body_part = block[:body_part] || block["body_part"]
          action_key = block[:action_key] || block["action_key"]

          # Combo blocks can cover multiple parts
          covered_parts = @config.dig("block_types", action_key, "body_parts") ||
            @config.dig("attack_types", action_key, "body_parts") ||
            [body_part]

          covered_parts.each do |part|
            unless %w[head torso stomach legs].include?(part)
              @errors << "Invalid body part in block #{index + 1}: #{part}"
            end
          end
        end
      end

      def validate_skills(skills)
        skills.each do |skill|
          key = skill[:key] || skill["key"]

          unless @config.dig("magic_types", key)
            @errors << "Unknown skill: #{key}"
          end
        end
      end

      def action_cost(action_key, config_section)
        return 0 unless action_key

        # Check simple/aimed attacks (no cost)
        return 0 if action_key == "simple"
        return 20 if action_key == "aimed" # Aimed has 20 AP cost

        @config.dig(config_section, action_key, "action_cost").to_i
      end

      def attack_penalty(attack_count)
        penalties = @config["attack_penalties"] || []
        penalty_entry = penalties.find { |p| p["attacks"] == attack_count }
        penalty_entry&.dig("penalty").to_i
      end

      def ap_limit
        if @participant&.battle
          @participant.battle.action_points_per_turn ||
            @config.dig("defaults", "action_points_per_turn") ||
            80
        else
          @config.dig("defaults", "action_points_per_turn") || 80
        end
      end
    end
  end
end
