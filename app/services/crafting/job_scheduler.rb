# frozen_string_literal: true

module Crafting
  # Creates crafting jobs and computes completion timestamps with respect to station capacity.
  #
  # Usage:
  #   Crafting::JobScheduler.new(user:, character:, recipe:, station:).enqueue!(quantity: 2)
  #
  # Returns:
  #   Array of CraftingJob records.
  class JobScheduler
    def initialize(user:, character:, recipe:, station:, validator: nil)
      @user = user
      @character = character
      @recipe = recipe
      @station = station
      @validator = validator || Crafting::RecipeValidator.new(character:, recipe:, station:)
      @virtual_finish_times = []
    end

    def enqueue!(quantity: 1)
      validator.validate!
      ApplicationRecord.transaction do
        jobs = []
        quantity.to_i.times do
          jobs << build_job!
        end
        jobs
      end
    end

    private

    attr_reader :user, :character, :recipe, :station, :validator, :virtual_finish_times

    def build_job!
      start_time = next_start_time
      duration_seconds = station.duration_for(recipe.duration_seconds)
      completes_at = start_time + duration_seconds.seconds
      outcome_preview = Professions::CraftingOutcomeCalculator.new(
        progress: validator.profession_progress,
        recipe: recipe,
        station: station
      ).preview

      job = CraftingJob.create!(
        user:,
        character:,
        recipe:,
        crafting_station: station,
        status: :queued,
        started_at: start_time,
        completes_at: completes_at,
        success_chance: outcome_preview.success_chance,
        quality_tier: outcome_preview.quality_tier,
        quality_score: outcome_preview.quality_score,
        portable_penalty_applied: station.portable?,
        batch_quantity: 1
      )
      register_finish!(completes_at)
      consume_resources!(job)
      schedule_completion(job)
      job
    end

    def next_start_time
      return Time.current unless station.capacity.positive?

      active_finish_times = station.crafting_jobs.active.order(:completes_at).pluck(:completes_at)
      combined = (active_finish_times + virtual_finish_times).sort
      if combined.size < station.capacity
        Time.current
      else
        [combined[station.capacity - 1], Time.current].max
      end
    end

    def register_finish!(completes_at)
      virtual_finish_times << completes_at
    end

    def consume_resources!(job)
      inventory = character.inventory
      inventory.consume_materials!(recipe.materials) if recipe.materials.present?
      if recipe.requires_premium_tokens?
        Payments::PremiumTokenLedger.debit(
          user: user,
          amount: recipe.premium_token_cost,
          reason: "crafting.premium_recipe",
          actor: user,
          reference: job
        )
      end
    end

    def schedule_completion(job)
      CraftingJobCompletionJob.set(wait_until: job.completes_at).perform_later(job.id)
    end
  end
end
