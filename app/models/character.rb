# frozen_string_literal: true

class Character < ApplicationRecord
  MAX_NAME_LENGTH = 30

  PRIMARY_STATS = %i[strength dexterity luck vitality intelligence].freeze
  BASE_PRIMARY_STATS = PRIMARY_STATS.index_with { 1 }.freeze
  STAT_LABELS = {
    strength: "Сила",
    dexterity: "Ловкость",
    luck: "Удача",
    vitality: "Здоровье",
    intelligence: "Знания"
  }.freeze
  STAT_ALIASES = {
    "strength" => :strength,
    "dexterity" => :dexterity,
    "luck" => :luck,
    "intelligence" => :intelligence,
    "vitality" => :vitality
  }.freeze

  ALIGNMENTS = {
    none: "none",
    law: "law",
    light: "light",
    balance: "balance",
    chaos: "chaos",
    dark: "dark"
  }.freeze
  ALIGNMENT_LABELS = {
    "none" => "Нет",
    "law" => "Закон",
    "light" => "Свет",
    "balance" => "Равновесие",
    "chaos" => "Хаос",
    "dark" => "Тьма"
  }.freeze

  EQUIPMENT_STAT_ALIASES = {
    "strength" => :strength,
    "dexterity" => :dexterity,
    "luck" => :luck,
    "intelligence" => :intelligence,
    "vitality" => :vitality
  }.freeze

  belongs_to :user

  has_one :position, class_name: "CharacterPosition", dependent: :destroy
  has_one :inventory, dependent: :destroy
  has_many :arena_applications, foreign_key: :applicant_id, dependent: :destroy
  has_many :arena_participations, dependent: :destroy

  has_many :movement_commands, dependent: :destroy
  has_many :world_action_offers, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: {maximum: MAX_NAME_LENGTH}
  validates :level, numericality: {greater_than: 0}
  validates :experience, numericality: {greater_than_or_equal_to: 0}
  validates :stat_points_available, numericality: {greater_than_or_equal_to: 0}
  validates :combat_skill_points, :peace_skill_points, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validates :fatigue_percent, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}
  validates :alignment, inclusion: {in: ALIGNMENTS.values}

  validate :respect_character_limit, on: :create

  after_create :ensure_inventory!

  def stats
    base = BASE_PRIMARY_STATS.dup
    allocated_stats.each do |stat, value|
      key = self.class.normalize_stat_key(stat)
      next unless key

      base[key] = base.fetch(key, 0) + value.to_i
    end
    equipment_stat_modifiers.each do |stat, value|
      base[stat] = base.fetch(stat, 0) + value.to_i
    end
    Game::Systems::StatBlock.new(base:)
  end

  def self.normalize_stat_key(key)
    STAT_ALIASES[key.to_s.strip.downcase.tr(" -", "_")]
  end

  def self.stat_label(key)
    STAT_LABELS.fetch(key.to_sym)
  end

  def self.xp_required_for_level(level)
    target = level.to_i
    return 0 if target <= 1

    ((target - 1)**2) * 100
  end

  def experience_to_next_level
    [self.class.xp_required_for_level(level + 1) - experience.to_i, 0].max
  end

  # Calculate maximum action points for combat
  # Formula: Base AP (50) + (Level × 3) + (Dexterity × 2)
  # This determines how many attacks/blocks a character can perform per turn
  #
  # @return [Integer] the character's maximum action points
  def max_action_points
    base_ap = 50
    level_bonus = level * 3
    dexterity_bonus = stats.get(:dexterity).to_i * 2

    base_ap + level_bonus + dexterity_bonus
  end

  def alignment_label
    ALIGNMENT_LABELS.fetch(alignment, "Нет")
  end

  def alignment_display
    alignment_label
  end

  # ===================
  # Abilities
  # ===================

  # Get available combat skill points (for combat/magic/resistance skills)
  #
  # @return [Integer] available combat skill points
  def available_combat_skill_points
    combat_skill_points.to_i
  end

  # Get available peace skill points
  #
  # @return [Integer] available peace skill points
  def available_peace_skill_points
    peace_skill_points.to_i
  end

  # Get available skill points for a specific pool
  #
  # @param pool [Symbol] :combat or :peace
  # @return [Integer] available points for that pool
  def available_skill_points_for_pool(pool)
    case pool.to_sym
    when :combat
      available_combat_skill_points
    when :peace
      available_peace_skill_points
    else
      0
    end
  end

  # Get available skill points for a specific skill
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] available points for that skill's pool
  def available_points_for_skill(skill_key)
    pool = Game::Skills::PassiveSkillRegistry.pool_for(skill_key)
    available_skill_points_for_pool(pool)
  end

  # Get the level of a passive skill (base level only, no equipment)
  #
  # @param skill_key [Symbol, String] the skill identifier (e.g., :wanderer)
  # @return [Integer] skill level (0-100, defaults to 0)
  def passive_skill_level(skill_key)
    base = (passive_skills[skill_key.to_s] || 0).to_i
    equipment_bonus = equipment_skill_bonus(skill_key)
    [base + equipment_bonus, 100].min
  end

  # Get the base level of a passive skill (without equipment bonuses)
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] base skill level (0-100, defaults to 0)
  def base_passive_skill_level(skill_key)
    (passive_skills[skill_key.to_s] || 0).to_i
  end

  # Set the level of a passive skill
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @param level [Integer] new level (clamped to 0-max_level)
  def set_passive_skill!(skill_key, level)
    key = skill_key.to_s
    max = Game::Skills::PassiveSkillRegistry.max_level(key)
    clamped = level.to_i.clamp(0, max)

    new_skills = passive_skills.merge(key => clamped)
    update!(passive_skills: new_skills)
  end

  # Increase a passive skill by a given amount
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @param amount [Integer] amount to increase (default 1)
  def increase_passive_skill!(skill_key, amount = 1)
    current = passive_skill_level(skill_key)
    set_passive_skill!(skill_key, current + amount)
  end

  # Spend a skill point on a skill using tiered progression
  # Returns the new level achieved
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer, nil] new skill level, or nil if cannot spend
  def spend_skill_point!(skill_key)
    key = skill_key.to_sym

    # Use the comprehensive can_spend? check
    spend_check = Game::Skills::PassiveSkillRegistry.can_spend?(key, self)
    unless spend_check[:allowed]
      errors&.add(:base, spend_check[:reason])
      return nil
    end

    definition = Game::Skills::PassiveSkillRegistry.find(key)
    pool = definition[:pool]
    current_level = base_passive_skill_level(key)  # Use base level, not effective

    # Calculate new level using tiered progression
    formula = Game::Formulas::SkillProgressionFormula.new
    new_level = formula.apply_spend(
      current_level: current_level,
      progression_rate: definition[:progression_rate]
    )

    # Apply the changes atomically
    transaction do
      new_skills = passive_skills.merge(key.to_s => new_level)

      case pool
      when :combat
        update!(
          passive_skills: new_skills,
          combat_skill_points: combat_skill_points - 1
        )
      when :peace
        update!(
          passive_skills: new_skills,
          peace_skill_points: peace_skill_points - 1
        )
      end
    end

    clear_passive_skill_cache!
    new_level
  end

  # Check if prerequisites are met for a skill
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Hash] { met: Boolean, missing: Array }
  def skill_prerequisites_met?(skill_key)
    Game::Skills::PassiveSkillRegistry.prerequisites_met?(skill_key, self)
  end

  # Get skills currently locked by prerequisites
  #
  # @return [Array<Hash>] array of locked skill info
  def locked_skills
    Game::Skills::PassiveSkillRegistry.locked_skills_for(self)
  end

  # Refund a skill point from a skill (undo during allocation)
  # Only works for points added this session (tracked separately)
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @param base_level [Integer] the level before this session's allocations
  # @return [Integer, nil] new skill level, or nil if cannot refund
  def refund_skill_point!(skill_key, base_level:)
    key = skill_key.to_sym
    definition = Game::Skills::PassiveSkillRegistry.find(key)
    return nil unless definition

    current_level = passive_skill_level(key)
    return nil if current_level <= base_level

    # Calculate previous level using tiered progression
    formula = Game::Formulas::SkillProgressionFormula.new
    new_level = formula.remove_spend(
      current_level: current_level,
      base_level: base_level,
      progression_rate: definition[:progression_rate]
    )

    pool = definition[:pool]

    # Apply the changes atomically
    transaction do
      new_skills = passive_skills.merge(key.to_s => new_level)

      case pool
      when :combat
        update!(
          passive_skills: new_skills,
          combat_skill_points: combat_skill_points + 1
        )
      when :peace
        update!(
          passive_skills: new_skills,
          peace_skill_points: peace_skill_points + 1
        )
      end
    end

    clear_passive_skill_cache!
    new_level
  end

  # Get points gained per spend for a skill at its current level
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] points that would be gained on next spend
  def skill_points_per_spend(skill_key)
    definition = Game::Skills::PassiveSkillRegistry.find(skill_key.to_sym)
    return 0 unless definition

    current_level = passive_skill_level(skill_key)
    formula = Game::Formulas::SkillProgressionFormula.new
    formula.points_per_spend(
      current_level: current_level,
      progression_rate: definition[:progression_rate]
    )
  end

  # Award skill points (typically from leveling up)
  #
  # @param combat_points [Integer] points to add to combat pool
  # @param peace_points [Integer] points to add to peace pool
  def award_skill_points!(combat_points: 0, peace_points: 0)
    updates = {}
    updates[:combat_skill_points] = combat_skill_points + combat_points if combat_points.positive?
    updates[:peace_skill_points] = peace_skill_points + peace_points if peace_points.positive?
    update!(updates) if updates.present?
  end

  # Get a calculator for all passive skill effects
  #
  # @return [Game::Skills::PassiveSkillCalculator]
  def passive_skill_calculator
    @passive_skill_calculator ||= Game::Skills::PassiveSkillCalculator.new(self)
  end

  # Clear the cached calculator (call after skill changes)
  def clear_passive_skill_cache!
    @passive_skill_calculator = nil
  end

  # ===================
  # Combat Stats
  # ===================

  # Calculate attack power for combat
  # Formula: (Strength × 2) + (Dexterity / 2) + (Level / 2) + equipment bonus
  #
  # @return [Integer] attack power value
  def attack_power
    base = stats.get(:strength).to_i * 2
    dex_bonus = stats.get(:dexterity).to_i / 2
    level_bonus = level.to_i / 2
    base + dex_bonus + level_bonus + equipment_attack_bonus
  end

  # Calculate defense for combat
  # Formula: Vitality + (Strength / 3) + (Level / 2) + equipment bonus
  #
  # @return [Integer] defense value
  def defense
    base = stats.get(:vitality).to_i
    str_bonus = stats.get(:strength).to_i / 3
    level_bonus = level.to_i / 2
    base + str_bonus + level_bonus + equipment_defense_bonus
  end

  # Calculate critical hit chance
  # Formula: Base 5% + (Dexterity / 5) + (Luck / 10), max 50%
  #
  # @return [Integer] crit chance percentage (0-50)
  def critical_chance
    base = 5
    dex_bonus = stats.get(:dexterity).to_i / 5
    luck_bonus = stats.get(:luck).to_i / 10
    [base + dex_bonus + luck_bonus, 50].min
  end

  def effective_max_hp
    read_attribute(:max_hp).to_i + equipment_effect_value("hp", "max_hp").to_i
  end

  def armor_pierce_percent
    equipment_effect_value("armor_pierce", "armor_piercing")
  end

  def fortitude_percent
    equipment_effect_value("fortitude", "physical_resistance")
  end

  def accuracy_bonus
    equipment_effect_value("accuracy")
  end

  def dodge_bonus
    equipment_effect_value("dodge", "evasion")
  end

  def elemental_resistance_percent(element)
    equipment_effect_value("#{element}_resistance", "all_resistances", "elemental_resistance")
  end

  def equipment_effect_value(*keys)
    return 0 unless inventory

    normalized_keys = keys.flatten.map { |key| normalize_equipment_effect_key(key) }
    inventory.inventory_items.equipped.includes(:item_template).sum do |item|
      next 0 if item.broken?

      normalized_effects = item.effect_modifiers.transform_keys { |key| normalize_equipment_effect_key(key) }
      normalized_keys.sum { |key| numeric_equipment_effect(normalized_effects[key]) }
    end
  end

  def degrade_equipped_items!(*slots, amount: 1)
    return [] unless inventory

    slot_keys = slots.flatten.compact.map(&:to_s)
    scope = inventory.inventory_items.equipped
    scope = scope.where(equipment_slot: slot_keys) if slot_keys.any?
    scope.filter_map do |item|
      next unless item.durable?

      item.decrement_durability!(amount)
      item
    end
  end

  # Break down combat-relevant derived stats for UI and balancing.
  #
  # @return [Hash] attack, defense, and critical components
  def combat_power_breakdown
    current_stats = stats
    attack_strength = current_stats.get(:strength).to_i * 2
    attack_dexterity = current_stats.get(:dexterity).to_i / 2
    attack_level = level.to_i / 2
    attack_equipment = equipment_attack_bonus

    defense_vitality = current_stats.get(:vitality).to_i
    defense_strength = current_stats.get(:strength).to_i / 3
    defense_level = level.to_i / 2
    defense_equipment = equipment_defense_bonus

    critical_base = 5
    critical_dexterity = current_stats.get(:dexterity).to_i / 5
    critical_luck = current_stats.get(:luck).to_i / 10

    {
      attack_power: {
        strength: attack_strength,
        dexterity: attack_dexterity,
        level: attack_level,
        equipment: attack_equipment,
        total: attack_strength + attack_dexterity + attack_level + attack_equipment
      },
      defense: {
        health: defense_vitality,
        strength: defense_strength,
        level: defense_level,
        equipment: defense_equipment,
        total: defense_vitality + defense_strength + defense_level + defense_equipment
      },
      critical_chance: {
        base: critical_base,
        dexterity: critical_dexterity,
        luck: critical_luck,
        total: [critical_base + critical_dexterity + critical_luck, 50].min
      },
      equipment_items: equipment_family_breakdown
    }
  end

  # Item-family combat contribution used by the arena combat UI and formulas.
  #
  # The family is taken only from explicit item metadata. Item names/slots do
  # not imply combat formula behavior.
  def equipment_family_breakdown
    return [] unless inventory

    inventory.inventory_items.equipped.includes(:item_template).map do |item|
      template = item.item_template
      family = equipment_item_family(item)

      {
        name: template&.name,
        slot: template&.slot,
        family:,
        attack: equipment_combat_component(item, "attack"),
        defense: equipment_combat_component(item, "defense")
      }
    end
  end

  # Get agility stat for initiative and flee calculations
  #
  # @return [Integer] agility value
  def agility
    stats.get(:dexterity).to_i
  end

  # ===================
  # Mana System
  # ===================

  # Calculate effective maximum MP.
  # Neverlands exposes `Быстрое восстановление маны` as an allocatable skill, but the
  # exact MP max/cost formulas are not source-captured yet.
  #
  # @return [Integer] effective maximum mana points
  def effective_max_mp
    read_attribute(:max_mp) || 50
  end

  # Return base mana cost until a Neverlands mana-cost formula is captured.
  #
  # @param base_cost [Integer] the original mana cost
  # @return [Integer] mana cost (minimum 1)
  def reduced_mana_cost(base_cost)
    [base_cost.to_i, 1].max
  end

  # Check if character has enough mana for a skill
  #
  # @param mana_cost [Integer] the mana required
  # @return [Boolean] true if sufficient mana
  def has_mana?(mana_cost)
    current_mp >= reduced_mana_cost(mana_cost)
  end

  # Spend mana with the current source-backed base cost.
  #
  # @param base_cost [Integer] the base mana cost
  # @return [Integer] actual mana spent
  def spend_mana!(base_cost)
    actual_cost = reduced_mana_cost(base_cost)
    new_mp = [current_mp - actual_cost, 0].max
    update!(current_mp: new_mp)
    actual_cost
  end

  # Regenerate mana (called at end of turn or on rest)
  # Base: 5% of effective_max_mp per tick
  #
  # @param ticks [Integer] number of regeneration ticks (default 1)
  # @return [Integer] amount regenerated
  def regenerate_mana!(ticks = 1)
    regen_per_tick = (effective_max_mp * 0.05).round
    total_regen = regen_per_tick * ticks
    new_mp = [current_mp + total_regen, effective_max_mp].min
    update!(current_mp: new_mp)
    total_regen
  end

  # ===================
  # Combat Status
  # ===================

  # Check if character is currently in combat
  # Convenience method for the in_combat boolean column
  #
  # @return [Boolean] true if character is in combat
  def in_combat?
    in_combat
  end

  # Mark character as entering combat
  #
  # @return [Boolean] true if update succeeded
  def enter_combat!
    update!(in_combat: true, last_combat_at: Time.current)
  end

  # Mark character as leaving combat
  #
  # @return [Boolean] true if update succeeded
  def exit_combat!
    update!(in_combat: false)
  end

  private

  # Get attack bonus from equipped items
  #
  # @return [Integer] total attack bonus from equipment
  def equipment_attack_bonus
    return 0 unless inventory

    inventory.inventory_items.equipped.includes(:item_template).sum do |item|
      next 0 if item.broken?

      equipment_combat_component(item, "attack")
    end
  end

  # Get defense bonus from equipped items
  #
  # @return [Integer] total defense bonus from equipment
  def equipment_defense_bonus
    return 0 unless inventory

    inventory.inventory_items.equipped.includes(:item_template).sum do |item|
      next 0 if item.broken?

      equipment_combat_component(item, "defense")
    end
  end

  def equipment_combat_component(item, stat_key)
    stats = item.effect_modifiers.transform_keys { |key| normalize_equipment_effect_key(key) }
    base = combat_component_base(stats, stat_key)
    return 0 if base.zero?

    base
  end

  def equipment_item_family(item)
    stats = item.effect_modifiers
    explicit = stats["family"] || stats[:family] || stats["weapon_family"] || stats[:weapon_family] ||
      item.properties&.dig("family") || item.properties&.dig("weapon_family")

    explicit.to_s.presence
  end

  # Get skill bonus from equipped items for a specific skill
  # Equipment can grant +X to passive skills (e.g., +5 sword_mastery from a sword)
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] total skill bonus from equipment
  def equipment_skill_bonus(skill_key)
    return 0 unless inventory

    key = skill_key.to_s
    inventory.inventory_items.equipped.includes(:item_template).sum do |item|
      next 0 if item.broken?

      skill_mods = item.effect_modifiers&.dig("skill_bonuses")
      next 0 unless skill_mods.is_a?(Hash)
      (skill_mods[key] || skill_mods[skill_key.to_sym]).to_i
    end
  end

  # Get elemental resistance bonus from equipped items
  # Equipment can grant resistance percentages (e.g., +5% fire_magic_resistance from a shield)
  #
  # @param element [Symbol, String] the element type (:fire, :cold, :lightning, :physical)
  # @return [Float] total resistance bonus from equipment (0.0 - 0.15 max)
  def equipped_items_resistance(element)
    return 0.0 unless inventory

    key = "#{element}_resistance"
    total = inventory.inventory_items.equipped.includes(:item_template).sum do |item|
      next 0.0 if item.broken?

      resist_mods = item.effect_modifiers&.dig("resistances")
      next 0.0 unless resist_mods.is_a?(Hash)
      (resist_mods[key] || resist_mods[element.to_s]).to_f
    end

    # Cap equipment resistance bonus at 15%
    total.clamp(0.0, 0.15)
  end

  # Get effective passive skill level (base + equipment bonus)
  # This is the combined level used in combat formulas
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] effective skill level (capped at 100)
  def effective_passive_skill_level(skill_key)
    base = passive_skill_level(skill_key)
    equipment_bonus = equipment_skill_bonus(skill_key)
    [base + equipment_bonus, 100].min
  end

  def equipment_stat_modifiers
    return {} unless inventory

    inventory.inventory_items.equipped.includes(:item_template).each_with_object(Hash.new(0)) do |item, totals|
      next if item.broken?

      item.effect_modifiers.each do |key, value|
        stat_key = EQUIPMENT_STAT_ALIASES[normalize_equipment_effect_key(key)]
        totals[stat_key] += numeric_equipment_effect(value) if stat_key
      end
    end
  end

  def combat_component_base(stats, stat_key)
    case stat_key.to_s
    when "attack"
      numeric_equipment_effect(stats["attack"]) +
        numeric_equipment_effect(stats["attack_power"]) +
        weapon_damage_average(stats)
    when "defense"
      numeric_equipment_effect(stats["defense"]) +
        numeric_equipment_effect(stats["armor"]) +
        numeric_equipment_effect(stats["armor_class"])
    else
      numeric_equipment_effect(stats[normalize_equipment_effect_key(stat_key)])
    end
  end

  def weapon_damage_average(stats)
    min = stats["damage_min"] || stats["min_damage"]
    max = stats["damage_max"] || stats["max_damage"]
    return 0 if min.blank? || max.blank?

    ((numeric_equipment_effect(min) + numeric_equipment_effect(max)) / 2.0).round
  end

  def normalize_equipment_effect_key(key)
    key.to_s.strip.downcase.tr(" -", "_")
  end

  def numeric_equipment_effect(value)
    return 0 if value.blank?

    value.to_s.delete("%+").to_f
  end

  def respect_character_limit
    return unless user

    if user.characters.count >= User::MAX_CHARACTERS
      errors.add(:base, "character limit reached")
    end
  end

  def ensure_inventory!
    create_inventory!(slot_capacity: 30, weight_capacity: 100) unless inventory
  end
end
