# frozen_string_literal: true

module Companions
  # CareTaskResolver tracks pet care mini-quests (feeding, grooming, scouting) and
  # awards bonding experience on completion.
  #
  # Usage:
  #   Companions::CareTaskResolver.new(pet: pet).perform!(:groom)
  #
  # Returns:
  #   Hash containing :bonding_xp and :rewards entries for UI display.
  class CareTaskResolver
    TASKS = {
      feed: {bonding_xp: 25, cooldown_minutes: 30, rewards: {items: ["treat"]}},
      groom: {bonding_xp: 40, cooldown_minutes: 45, rewards: {cosmetics: ["shiny_coat"]}},
      scout: {bonding_xp: 60, cooldown_minutes: 90, rewards: {gathering_bonus: 5}}
    }.freeze

    def initialize(pet:, rng: Random.new(1))
      @pet = pet
      @rng = rng
    end

    def perform!(task_key)
      task = TASKS.fetch(task_key.to_sym) { raise ArgumentError, "Unknown care task #{task_key}" }
      raise StandardError, "Care task on cooldown" unless pet.care_available?

      pet.apply_care!(
        task_key: task_key,
        bonding_xp: task[:bonding_xp],
        cooldown_minutes: task[:cooldown_minutes]
      )
      apply_rewards(task[:rewards], task[:bonding_xp])
    end

    private

    attr_reader :pet, :rng

    def apply_rewards(rewards, bonding_xp)
      metadata = pet.care_state.merge("last_rewards" => rewards)
      pet.update!(care_state: metadata)
      {bonding_xp:, rewards: rewards}
    end
  end
end
