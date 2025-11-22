# frozen_string_literal: true

module Professions
  # GatheringResolver determines whether a gathering attempt succeeds and rewards items.
  #
  # Usage:
  #   Professions::GatheringResolver.new(progress:, node:).harvest!
  #
  # Returns:
  #   Hash with :success boolean plus :rewards payload.
  class GatheringResolver
    def initialize(progress:, node:, rng: Random.new(1))
      @progress = progress
      @node = node
      @rng = rng
    end

    def harvest!
      ensure_profession_match!

      if rng.rand(100) < success_rate
        progress.gain_experience!(node.difficulty * 5)
        {success: true, rewards: node.rewards}
      else
        {success: false, cooldown: node.respawn_seconds}
      end
    end

    private

    attr_reader :progress, :node, :rng

    def success_rate
      base = 40
      skill_gap = progress.skill_level - node.difficulty
      (base + (skill_gap * 5)).clamp(5, 95)
    end

    def ensure_profession_match!
      return if progress.profession_id == node.profession_id

      raise Pundit::NotAuthorizedError, "Wrong profession for node"
    end
  end
end

