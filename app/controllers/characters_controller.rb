# frozen_string_literal: true

# CharactersController handles the Neverlands-style character profile allocation
# surfaces currently implemented: primary stats, numeric skills, and binary
# perks.
#
# Usage:
#   GET /characters/:id/stats       - Show stat allocation page
#   PATCH /characters/:id/stats     - Save stat allocations
#   GET /characters/:id/skills      - Show numeric skill allocation page
#   PATCH /characters/:id/skills    - Save numeric skill allocations
#   GET /characters/:id/perks       - Show boolean perk allocation page
#   PATCH /characters/:id/perks     - Save boolean perk allocations
class CharactersController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_character
  before_action :authorize_character!
  before_action :set_equipment, only: [:stats, :skills, :perks]

  # GET /characters/:id/stats
  def stats
    @stats_data = build_stats_data
    @allocatable_stats = allocatable_stat_keys
  end

  # PATCH /characters/:id/stats
  def update_stats
    allocated = parse_stat_allocations(params[:allocated_stats])
    Characters::StatAllocationService.new(character: @character).call(allocations: allocated)

    respond_to do |format|
      format.html { redirect_to stats_character_path(@character), notice: "Stats saved" }
      format.turbo_stream do
        @stats_data = build_stats_data
        @allocatable_stats = allocatable_stat_keys
        render turbo_stream: [
          turbo_stream.replace("stat-allocation", partial: "characters/stat_allocation"),
          turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: "Stats saved"})
        ]
      end
    end
  rescue Characters::StatAllocationService::AllocationError => e
    respond_with_error(e.message)
  end

  # GET /characters/:id/skills
  def skills
    @skills_data = build_skills_data
    @skill_definitions = Game::Skills::PassiveSkillRegistry.all
    @skill_categories = Game::Skills::PassiveSkillRegistry.categories
    @combat_skill_points = @character.available_combat_skill_points
    @peace_skill_points = @character.available_peace_skill_points
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
    Characters::SkillAllocationService.new(character: @character).call(allocations: allocated)

    respond_to do |format|
      format.html { redirect_to skills_character_path(@character), notice: "Skills saved" }
      format.turbo_stream do
        @skills_data = build_skills_data
        @skill_definitions = Game::Skills::PassiveSkillRegistry.all
        @skill_categories = Game::Skills::PassiveSkillRegistry.categories
        @combat_skill_points = @character.available_combat_skill_points
        @peace_skill_points = @character.available_peace_skill_points
        render turbo_stream: [
          turbo_stream.replace("skill-allocation", partial: "characters/skill_allocation"),
          turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: "Skills saved"})
        ]
      end
    end
  rescue Characters::SkillAllocationService::AllocationError => e
    respond_with_error(e.message)
  end

  # GET /characters/:id/perks
  def perks
    build_perks_data
  end

  # PATCH /characters/:id/perks
  def update_perks
    selected_keys = parse_perk_selections(params[:selected_perks])
    Game::Skills::PerkAllocation.new(@character).call(selected_keys:)

    respond_to do |format|
      format.html { redirect_to perks_character_path(@character), notice: "Perks saved" }
      format.turbo_stream do
        build_perks_data
        render turbo_stream: [
          turbo_stream.replace("perk-allocation", partial: "characters/perk_allocation"),
          turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: "Perks saved"})
        ]
      end
    end
  rescue Game::Skills::PerkAllocation::AllocationError => e
    respond_with_error(e.message, fallback_location: perks_character_path(@character))
  end

  private

  def set_equipment
    @equipment = @character.inventory.inventory_items.equipped.includes(:item_template).index_by do |item|
      item.equipment_slot.to_s.presence || item.item_template&.slot.to_s
    end
  end

  def set_character
    @character = Character.find(params[:id])
  end

  def authorize_character!
    authorize @character, :manage_progression?
  rescue Pundit::NotAuthorizedError
    redirect_to root_path, alert: "You can only manage your own character."
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
    @perk_definitions = Game::Skills::PerkRegistry.all
    @perk_points = @character.perk_points.to_i
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

  def parse_perk_selections(perk_params)
    return [] unless perk_params.is_a?(ActionController::Parameters) || perk_params.is_a?(Hash)

    selected_keys = []
    perk_params.each_pair do |key, selected|
      selected_keys << key.to_s if ActiveModel::Type::Boolean.new.cast(selected)
    end
    selected_keys
  end

  def respond_with_error(message, fallback_location: root_path)
    respond_to do |format|
      format.html { redirect_back fallback_location:, alert: message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("flash", partial: "shared/flash", locals: {type: "alert", message: message})
      end
    end
  end
end
