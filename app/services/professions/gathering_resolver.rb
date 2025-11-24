# frozen_string_literal: true

module Professions
  # GatheringResolver determines whether a gathering attempt succeeds and rewards items.
  #
  # Usage:
  #   Professions::GatheringResolver.new(progress:, node:, party_size:).harvest!
  #
  # Returns:
  #   Hash with :success boolean, :rewards payload, and respawn timing metadata.
  class GatheringResolver
    def initialize(progress:, node:, party_size: 1, rng: Random.new(1))
      @progress = progress
      @node = node
      @party_size = [party_size.to_i, 1].max
      @rng = rng
    end

    def harvest!
      ensure_profession_match!
      ensure_node_available!

      if rng.rand(100) < success_rate
        progress.gain_experience!(node.difficulty * 5)
        node.mark_harvest!(party_size:)
        {
          success: true,
          rewards: node.rewards,
          respawn_at: node.next_available_at
        }
      else
        progress.gain_experience!(node.difficulty)
        cooldown = node.effective_respawn_seconds(party_size: party_size)
        {success: false, cooldown: cooldown}
      end
    end

    private

    attr_reader :progress, :node, :party_size, :rng

    def success_rate
      base = 45
      skill_gap = progress.skill_level - node.difficulty
      bonuses = location_bonus + group_bonus
      (base + (skill_gap * 4) + bonuses).clamp(10, 95)
    end

    def location_bonus
      progress.location_bonus_for(node.zone)
    end

    def group_bonus
      return 0 if party_size <= 1

      (party_size - 1) * node.group_bonus_percent
    end

    def ensure_profession_match!
      return if progress.profession_id == node.profession_id

      raise Pundit::NotAuthorizedError, "Wrong profession for node"
    end

    def ensure_node_available!
      return if node.available?

      raise StandardError, "Node is respawning"
    end
  end
end
