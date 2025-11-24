# frozen_string_literal: true

module Professions
  # Resolves a crafting job, applying rewards, XP, tool wear, and achievements.
  #
  # Usage:
  #   Professions::CraftingOutcomeResolver.new(job:).call
  #
  # Returns:
  #   Professions::CraftingOutcomeCalculator::Result
  class CraftingOutcomeResolver
    def initialize(job:, rng: Random.new(1))
      @job = job
      @progress = job.character.profession_progresses.find_by!(profession: job.profession)
      @rng = rng
    end

    def call
      outcome = calculator.resolve!
      apply_result!(outcome)
      outcome
    end

    private

    attr_reader :job, :progress, :rng

    def calculator
      @calculator ||= Professions::CraftingOutcomeCalculator.new(
        progress: progress,
        recipe: recipe,
        station: job.crafting_station,
        tool: progress.best_tool,
        rng: rng
      )
    end

    def apply_result!(outcome)
      if outcome.success
        payload = grant_rewards!
        advance_progress!(recipe.tier * 20)
        job.update!(
          status: :completed,
          quality_tier: outcome.quality_tier,
          quality_score: outcome.quality_score,
          result_payload: job.result_payload
            .merge(payload)
            .merge("quality" => outcome.quality_tier)
        )
      else
        advance_progress!(recipe.tier * 10)
        job.update!(
          status: :failed,
          result_payload: job.result_payload.merge("failure" => true)
        )
      end

      apply_tool_wear!
      update_guild_missions!(outcome) if outcome.success
      grant_achievements!(outcome) if outcome.success
    end

    def grant_rewards!
      rewards = recipe.rewards.fetch("items", [])
      rewards.each do |reward|
        job.character.inventory.add_item_by_name!(reward["name"], quantity: reward["quantity"].to_i)
      end

      {"items" => rewards}
    end

    def advance_progress!(xp_amount)
      progress.gain_experience!(xp_amount)
    end

    def apply_tool_wear!
      wear = recipe.requirements.fetch("tool_wear", 5).to_i
      Professions::ToolMaintenance.degrade!(tool: progress.best_tool, amount: wear)
    end

    def update_guild_missions!(outcome)
      guild = job.character.guild
      return unless guild

      guild.guild_missions.incomplete.where(required_profession: job.profession).find_each do |mission|
        crafted_item_names = recipe.rewards.fetch("items", []).map { |reward| reward["name"] }
        next unless crafted_item_names.include?(mission.required_item_name)

        mission.apply_progress!(1)
      end
    end

    def grant_achievements!(outcome)
      achievement_key =
        case outcome.quality_tier
        when "legendary"
          "legendary_artisan"
        when "epic"
          "master_artisan"
        end

      return unless achievement_key

      achievement = Achievement.find_by(key: achievement_key)
      return unless achievement

      Achievements::GrantService.new(user: job.user, achievement: achievement).call(source: "crafting")
    end

    def recipe
      job.recipe
    end
  end
end
