# frozen_string_literal: true

module Arena
  # Deterministic AI decision-making for NPC arena combat
  # Makes combat decisions based on AI behavior type and current battle state
  #
  # Purpose: Control NPC actions during arena fights
  #
  # Architecture:
  #   This service uses the unified NPC architecture via Npc::CombatStats and Npc::Combatable
  #   concerns included in NpcTemplate. Stats and behaviors are derived from the template's
  #   combat_stats and combat_behavior methods, ensuring consistency with outside-world combat.
  #
  # Inputs:
  #   - npc_template: NpcTemplate for the arena bot (includes Npc::CombatStats, Npc::Combatable)
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

    attr_reader :npc_template, :match, :rng, :behavior

    # Initialize the combat AI
    #
    # @param npc_template [NpcTemplate] the NPC fighting (with Npc::Combatable)
    # @param match [ArenaMatch] the arena match
    # @param rng [Random] seeded random for determinism
    def initialize(npc_template:, match:, rng: Random.new(1))
      @npc_template = npc_template
      @match = match
      @rng = rng
      # Use unified combat_behavior from Npc::Combatable concern
      @behavior = npc_template.combat_behavior
    end

    # Decide what action the NPC should take
    # Uses Npc::Combatable#should_defend? for unified defense decision logic
    #
    # @return [Decision] the action decision
    def decide_action
      npc_participation = find_npc_participation
      hp_ratio = calculate_hp_ratio(npc_participation)

      # Use unified should_defend? from Npc::Combatable concern
      if npc_template.should_defend?(current_hp_ratio: hp_ratio, rng: rng)
        return Decision.new(action_type: :defend, target: nil, params: {})
      end

      # Default to attack
      attack_decision
    end

    # Get NPC stats for combat calculations
    # Delegates to unified combat_stats from Npc::CombatStats concern
    #
    # @return [Hash] stats hash
    def stats
      @stats ||= npc_template.combat_stats
    end

    private

    def attack_decision
      target = find_best_target
      attacks = select_attack_package
      first_attack = attacks.first || {body_part: "torso", action_key: "simple"}

      Decision.new(
        action_type: :attack,
        target: target,
        params: {
          body_part: first_attack[:body_part],
          attack_type: first_attack[:action_key],
          attacks:
        }
      )
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

    def select_attack_package
      participation = find_npc_participation
      profile = participation ? Arena::CombatProfile.for_participation(participation, persist: true) : {}
      ap_limit = profile.fetch("ap_limit", Game::Combat::ActionCatalog::DEFAULT_AP_PER_TURN).to_i
      simple_cost = profile.fetch("simple_attack_cost", Game::Combat::ActionCatalog.attack_cost("simple")).to_i
      max_attacks = configured_max_attacks

      attacks = []
      max_attacks.times do
        body_part = select_body_part(excluding_parts: attacks.map { |attack| attack[:body_part] })
        candidate = attacks + [{action_key: "simple", body_part:}]
        break if candidate.size > 1 && attack_package_cost(candidate, simple_cost) > ap_limit

        attacks = candidate
      end

      attacks.presence || [{action_key: "simple", body_part: "torso"}]
    end

    def configured_max_attacks
      configured = npc_template.metadata&.dig("max_attacks_per_turn").to_i
      return configured.clamp(1, 4) if configured.positive?

      case behavior
      when :aggressive then 3
      when :defensive then 1
      else 2
      end
    end

    def attack_package_cost(attacks, simple_cost)
      attacks.size * simple_cost + Game::Combat::ActionCatalog.attack_penalty(attacks.size)
    end

    def select_body_part(excluding_parts: [])
      # The source UI allows multiple attacks, except a head+legs combination.
      body_parts = %w[head torso stomach legs]
      excluded = Array(excluding_parts).map(&:to_s)
      candidates = body_parts.reject do |part|
        (part == "head" && excluded.include?("legs")) ||
          (part == "legs" && excluded.include?("head"))
      end

      candidates.sample(random: rng) || "torso"
    end
  end
end
