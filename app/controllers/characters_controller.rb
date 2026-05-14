# frozen_string_literal: true

# CharactersController handles the Neverlands-style character profile allocation
# surfaces: primary stats, numeric skills, and boolean perks.
#
# Usage:
#   GET /characters/:id/stats       - Show stat allocation page
#   PATCH /characters/:id/stats     - Save stat allocations
#   GET /characters/:id/skills      - Show numeric skill allocation page
#   PATCH /characters/:id/skills    - Save numeric skill allocations
#   GET /characters/:id/perks       - Show boolean perk allocation page
#   PATCH /characters/:id/perks     - Save one selected perk
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
    @skill_categories = Game::Skills::PassiveSkillRegistry.categories
    @combat_skill_points = @character.available_combat_skill_points
    @peace_skill_points = @character.available_peace_skill_points
  end

  # GET /characters/:id/perks
  def perks
    build_perks_data
  end

  # PATCH /characters/:id/skills
  # Handles skill point allocation with tiered progression and dual pools.
  #
  # Params:
  #   allocated_skills: Hash of skill_key => spends_count (how many times to spend on this skill)
  #
  # Each "spend" uses 1 point from the appropriate pool (combat or peace) and
  # grants skill levels based on the skill's tiered progression rate.
  def update_skills
    allocated = parse_skill_allocations(params[:allocated_skills])

    if allocated.values.sum <= 0
      return respond_with_error("No skills allocated")
    end

    # Separate allocations by pool type (skip unknown skills)
    combat_allocations = {}
    peace_allocations = {}

    allocated.each do |skill_key, spends|
      next unless spends.positive?
      # Skip unknown skills entirely - they shouldn't consume points
      definition = Game::Skills::PassiveSkillRegistry.find(skill_key.to_sym)
      next unless definition

      pool = definition[:pool] || :combat
      case pool
      when :combat
        combat_allocations[skill_key] = spends
      when :peace
        peace_allocations[skill_key] = spends
      end
    end

    # Validate we have enough points in each pool
    combat_spends_total = combat_allocations.values.sum
    peace_spends_total = peace_allocations.values.sum

    if combat_spends_total > @character.available_combat_skill_points
      return respond_with_error("Not enough combat skill points (need #{combat_spends_total}, have #{@character.available_combat_skill_points})")
    end

    if peace_spends_total > @character.available_peace_skill_points
      return respond_with_error("Not enough peace skill points (need #{peace_spends_total}, have #{@character.available_peace_skill_points})")
    end

    # Apply tiered progression for each skill spend
    formula = Game::Formulas::SkillProgressionFormula.new
    skill_updates = {}

    allocated.each do |skill_key, spends|
      next unless spends.positive?
      definition = Game::Skills::PassiveSkillRegistry.find(skill_key.to_sym)
      next unless definition

      current_level = @character.passive_skill_level(skill_key)
      max_level = definition[:max_level] || 100

      # Apply each spend sequentially (tiered progression changes per tier)
      spends.times do
        break if current_level >= max_level
        current_level = formula.apply_spend(
          current_level: current_level,
          progression_rate: definition[:progression_rate]
        )
      end

      skill_updates[skill_key.to_s] = [current_level, max_level].min
    end

    # Apply all updates atomically
    @character.transaction do
      new_skills = @character.passive_skills.merge(skill_updates)

      @character.update!(
        passive_skills: new_skills,
        combat_skill_points: @character.combat_skill_points - combat_spends_total,
        peace_skill_points: @character.peace_skill_points - peace_spends_total,
        skill_points_available: @character.skill_points_available - (combat_spends_total + peace_spends_total)
      )
    end

    @character.clear_passive_skill_cache!

    respond_to do |format|
      format.html { redirect_to skills_character_path(@character), notice: "Skills allocated successfully!" }
      format.turbo_stream do
        @skills_data = build_skills_data
        @skill_definitions = Game::Skills::PassiveSkillRegistry.all
        @skill_categories = Game::Skills::PassiveSkillRegistry.categories
        @combat_skill_points = @character.available_combat_skill_points
        @peace_skill_points = @character.available_peace_skill_points
        render turbo_stream: [
          turbo_stream.replace("skill-allocation", partial: "characters/skill_allocation"),
          turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: "Skills allocated!"})
        ]
      end
    end
  end

  # PATCH /characters/:id/perks
  def update_perks
    perk_key = params[:perk_key].presence

    if perk_key.blank?
      return respond_with_error("No perk selected")
    end

    if @character.select_perk!(perk_key)
      redirect_to perks_character_path(@character), notice: "Perk selected successfully!"
    else
      respond_with_error(@character.errors.full_messages.to_sentence.presence || "Perk cannot be selected")
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
    allocated = @character.allocated_stats || {}
    effective_stats = @character.stats

    Character::PRIMARY_STATS.index_with do |stat_key|
      {
        label: Character.stat_label(stat_key),
        base: Character::BASE_PRIMARY_STATS.fetch(stat_key),
        allocated: allocated.sum { |key, value| (Character.normalize_stat_key(key) == stat_key) ? value.to_i : 0 },
        total: effective_stats.get(stat_key)
      }
    end
  end

  def allocatable_stat_keys
    Character::PRIMARY_STATS
  end

  def build_skills_data
    formula = Game::Formulas::SkillProgressionFormula.new
    skills = {}

    Game::Skills::PassiveSkillRegistry.all.each do |key, definition|
      current_level = @character.passive_skill_level(key)
      max_level = definition[:max_level] || 100
      points_per_spend = formula.points_per_spend(
        current_level: current_level,
        progression_rate: definition[:progression_rate]
      )

      skills[key] = {
        level: current_level,
        max_level: max_level,
        name: definition[:name],
        description: definition[:description],
        category: definition[:category],
        pool: definition[:pool],
        progression_rate: definition[:progression_rate],
        points_per_spend: points_per_spend,
        at_max: current_level >= max_level
      }
    end
    skills
  end

  def build_perks_data
    @perk_categories = Game::Skills::PerkRegistry.categories
    @perks_by_category = Game::Skills::PerkRegistry.grouped_by_category
    @selected_perks = @character.selected_perks
    @excluded_perks = @selected_perks.flat_map { |key| Game::Skills::PerkRegistry.excluded_by(key) }.map(&:to_s).uniq
  end

  def parse_stat_allocations(stat_params)
    return {} unless stat_params.is_a?(ActionController::Parameters) || stat_params.is_a?(Hash)

    result = Hash.new(0)
    stat_params.each do |key, value|
      normalized = Character.normalize_stat_key(key)
      next unless normalized

      result[normalized.to_s] += value.to_i.clamp(0, 100)
    end
    result.to_h
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
