# frozen_string_literal: true

# CharactersController handles character profile management including
# stat and skill allocation. Follows Neverlands-inspired UI/UX patterns
# with client-side +/- allocation before server submission.
#
# Usage:
#   GET /characters/:id/stats       - Show stat allocation page
#   PATCH /characters/:id/stats     - Save stat allocations
#   GET /characters/:id/skills      - Show passive skill allocation page
#   PATCH /characters/:id/skills    - Save passive skill allocations
class CharactersController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_character
  before_action :authorize_character!

  # GET /characters/:id/stats
  def stats
    @stats_data = build_stats_data
    @allocatable_stats = allocatable_stat_keys
  end

  # PATCH /characters/:id/stats
  def update_stats
    allocated = parse_stat_allocations(params[:allocated_stats])
    total_spent = allocated.values.sum

    if total_spent > @character.stat_points_available
      return respond_with_error("Not enough stat points available")
    end

    if total_spent <= 0
      return respond_with_error("No stats allocated")
    end

    # Merge with existing allocated stats
    new_allocated = @character.allocated_stats.dup
    allocated.each do |stat, amount|
      next unless amount.positive?
      new_allocated[stat.to_s] = (new_allocated[stat.to_s] || 0) + amount
    end

    @character.update!(
      allocated_stats: new_allocated,
      stat_points_available: @character.stat_points_available - total_spent
    )

    respond_to do |format|
      format.html { redirect_to stats_character_path(@character), notice: "Stats allocated successfully!" }
      format.turbo_stream do
        @stats_data = build_stats_data
        @allocatable_stats = allocatable_stat_keys
        render turbo_stream: [
          turbo_stream.replace("stat-allocation", partial: "characters/stat_allocation"),
          turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: "Stats allocated!"})
        ]
      end
    end
  end

  # GET /characters/:id/skills
  def skills
    @skills_data = build_skills_data
    @skill_definitions = Game::Skills::PassiveSkillRegistry.all
  end

  # PATCH /characters/:id/skills
  def update_skills
    allocated = parse_skill_allocations(params[:allocated_skills])
    total_requested = allocated.values.sum

    # Validate we have enough points for requested allocation
    if total_requested > @character.skill_points_available
      return respond_with_error("Not enough skill points available")
    end

    if total_requested <= 0
      return respond_with_error("No skills allocated")
    end

    # Calculate actual points that will be used (considering max levels)
    actual_spent = 0
    skill_updates = {}

    allocated.each do |skill_key, amount|
      next unless amount.positive?
      current_level = @character.passive_skill_level(skill_key)
      max_level = Game::Skills::PassiveSkillRegistry.max_level(skill_key)
      new_level = [current_level + amount, max_level].min
      points_actually_used = new_level - current_level
      actual_spent += points_actually_used
      skill_updates[skill_key.to_s] = new_level
    end

    # Apply skill updates
    skill_updates.each do |key, level|
      @character.passive_skills[key] = level
    end

    @character.update!(
      passive_skills: @character.passive_skills,
      skill_points_available: @character.skill_points_available - actual_spent
    )
    @character.clear_passive_skill_cache!

    respond_to do |format|
      format.html { redirect_to skills_character_path(@character), notice: "Skills allocated successfully!" }
      format.turbo_stream do
        @skills_data = build_skills_data
        @skill_definitions = Game::Skills::PassiveSkillRegistry.all
        render turbo_stream: [
          turbo_stream.replace("skill-allocation", partial: "characters/skill_allocation"),
          turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: "Skills allocated!"})
        ]
      end
    end
  end

  private

  def set_character
    @character = Character.find(params[:id])
  end

  def authorize_character!
    unless @character.user_id == current_user.id
      redirect_to root_path, alert: "You can only manage your own characters."
    end
  end

  def build_stats_data
    base_stats = @character.character_class&.base_stats || {}
    allocated = @character.allocated_stats || {}

    {
      strength: {
        base: base_stats["strength"] || 10,
        allocated: allocated["strength"] || 0,
        total: @character.stats.get(:strength)
      },
      dexterity: {
        base: base_stats["dexterity"] || 10,
        allocated: allocated["dexterity"] || 0,
        total: @character.stats.get(:dexterity)
      },
      intelligence: {
        base: base_stats["intelligence"] || 10,
        allocated: allocated["intelligence"] || 0,
        total: @character.stats.get(:intelligence)
      },
      constitution: {
        base: base_stats["constitution"] || 10,
        allocated: allocated["constitution"] || 0,
        total: @character.stats.get(:constitution)
      },
      agility: {
        base: base_stats["agility"] || 10,
        allocated: allocated["agility"] || 0,
        total: @character.stats.get(:agility)
      },
      luck: {
        base: base_stats["luck"] || 10,
        allocated: allocated["luck"] || 0,
        total: @character.stats.get(:luck)
      }
    }
  end

  def allocatable_stat_keys
    %i[strength dexterity intelligence constitution agility luck]
  end

  def build_skills_data
    skills = {}
    Game::Skills::PassiveSkillRegistry.all.each do |key, definition|
      skills[key] = {
        level: @character.passive_skill_level(key),
        max_level: definition[:max_level],
        name: definition[:name],
        description: definition[:description],
        category: definition[:category]
      }
    end
    skills
  end

  def parse_stat_allocations(stat_params)
    return {} unless stat_params.is_a?(ActionController::Parameters) || stat_params.is_a?(Hash)

    result = {}
    stat_params.each do |key, value|
      result[key.to_s] = value.to_i.clamp(0, 100)
    end
    result
  end

  def parse_skill_allocations(skill_params)
    return {} unless skill_params.is_a?(ActionController::Parameters) || skill_params.is_a?(Hash)

    result = {}
    skill_params.each do |key, value|
      result[key.to_s] = value.to_i.clamp(0, 100)
    end
    result
  end

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("flash", partial: "shared/flash", locals: {type: "alert", message: message})
      end
    end
  end
end
