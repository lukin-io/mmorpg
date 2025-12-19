# frozen_string_literal: true

module Arena
  # Deterministic AI decision-making for NPC arena combat
  # Makes combat decisions based on AI behavior type and current battle state
  #
  # Purpose: Control NPC actions during arena fights
  #
  # Inputs:
  #   - npc_template: NpcTemplate for the arena bot
  #   - match: ArenaMatch the NPC is fighting in
  #   - rng: Seeded Random instance for deterministic behavior
  #
  # Returns:
  #   Decision struct with action_type, target, and params
  #
  # Usage:
  #   ai = Arena::NpcCombatAi.new(npc_template: template, match: match, rng: Random.new(123))
  #   decision = ai.decide_action
  #   # => Decision(action_type: :attack, target: character, params: {})
  #
  class NpcCombatAi
    Decision = Struct.new(:action_type, :target, :params, keyword_init: true)

    # AI behavior thresholds
    DEFEND_HP_THRESHOLD_DEFENSIVE = 0.7 # Defensive AI defends below 70% HP
    DEFEND_HP_THRESHOLD_BALANCED = 0.4  # Balanced AI defends below 40% HP
    DEFEND_CHANCE_DEFENSIVE = 0.4       # 40% chance to defend when appropriate
    DEFEND_CHANCE_BALANCED = 0.2        # 20% chance to defend when appropriate

    attr_reader :npc_template, :match, :rng, :behavior

    # Initialize the combat AI
    #
    # @param npc_template [NpcTemplate] the NPC fighting
    # @param match [ArenaMatch] the arena match
    # @param rng [Random] seeded random for determinism
    def initialize(npc_template:, match:, rng: Random.new(1))
      @npc_template = npc_template
      @match = match
      @rng = rng
      @behavior = npc_template.ai_behavior.to_sym
    end

    # Decide what action the NPC should take
    #
    # @return [Decision] the action decision
    def decide_action
      case behavior
      when :defensive
        defensive_decision
      when :aggressive
        aggressive_decision
      else
        balanced_decision
      end
    end

    # Get NPC stats for combat calculations
    #
    # @return [Hash] stats hash
    def stats
      @stats ||= begin
        npc_config = Game::World::ArenaNpcConfig.find_npc(npc_template.npc_key)
        if npc_config
          Game::World::ArenaNpcConfig.extract_stats(npc_config)
        else
          fallback_stats
        end
      end
    end

    private

    def defensive_decision
      npc_participation = find_npc_participation
      hp_ratio = calculate_hp_ratio(npc_participation)

      # Defend when HP is below threshold
      if hp_ratio < DEFEND_HP_THRESHOLD_DEFENSIVE && rng.rand < DEFEND_CHANCE_DEFENSIVE
        return Decision.new(action_type: :defend, target: nil, params: {})
      end

      # Otherwise attack
      attack_decision
    end

    def aggressive_decision
      # Aggressive AI always attacks
      attack_decision
    end

    def balanced_decision
      npc_participation = find_npc_participation
      hp_ratio = calculate_hp_ratio(npc_participation)

      # Sometimes defend when HP is low
      if hp_ratio < DEFEND_HP_THRESHOLD_BALANCED && rng.rand < DEFEND_CHANCE_BALANCED
        return Decision.new(action_type: :defend, target: nil, params: {})
      end

      attack_decision
    end

    def attack_decision
      target = find_best_target
      Decision.new(action_type: :attack, target: target, params: select_body_part)
    end

    def find_best_target
      # Find opponent with lowest HP
      opponents = match.arena_participations
        .where.not(npc_template_id: npc_template.id)
        .includes(:character)

      alive_opponents = opponents.select do |p|
        hp = p.npc? ? p.current_hp : p.character&.current_hp
        hp.to_i > 0
      end

      return nil if alive_opponents.empty?

      # Target lowest HP opponent
      alive_opponents.min_by do |p|
        p.npc? ? p.current_hp : p.character&.current_hp.to_i
      end&.character
    end

    def find_npc_participation
      match.arena_participations.find_by(npc_template_id: npc_template.id)
    end

    def calculate_hp_ratio(participation)
      return 1.0 unless participation

      current = participation.current_hp.to_f
      max = participation.max_hp.to_f
      return 1.0 if max.zero?

      current / max
    end

    def select_body_part
      # Randomly select body part to target
      body_parts = %w[head torso stomach legs]
      {body_part: body_parts.sample(random: rng)}
    end

    def fallback_stats
      level = npc_template.level || 1
      {
        attack: npc_template.metadata&.dig("base_damage") || (level * 3 + 5),
        defense: level * 2 + 3,
        agility: level + 5,
        hp: npc_template.health || (level * 10 + 20),
        crit_chance: 10
      }.with_indifferent_access
    end
  end
end
