# frozen_string_literal: true

module Professions
  # GatheringResolver determines whether a gathering attempt succeeds and rewards items.
  #
  # Usage:
  #   Professions::GatheringResolver.new(progress:, node:).harvest!
  #
  # Returns:
  #   Hash with :success boolean, :rewards payload, and respawn timing metadata.
  class GatheringResolver
    def initialize(progress:, node:, rng: Random.new(1))
      @progress = progress
      @node = node
      @rng = rng
    end

    def harvest!
      ensure_profession_match!
      ensure_node_available!

      if rng.rand(100) < success_rate
        progress.gain_experience!(node.difficulty * 5)
        node.mark_harvest!
        {
          success: true,
          rewards: node.rewards,
          respawn_at: node.next_available_at
        }
      else
        progress.gain_experience!(node.difficulty)
        cooldown = node.effective_respawn_seconds
        {success: false, cooldown: cooldown}
      end
    end

    private

    attr_reader :progress, :node, :rng

    def success_rate
      base = 45
      skill_gap = progress.skill_level - node.difficulty
      (base + (skill_gap * 4) + location_bonus).clamp(10, 95)
    end

    def location_bonus
      progress.location_bonus_for(node.zone)
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
