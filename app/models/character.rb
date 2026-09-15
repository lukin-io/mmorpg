# frozen_string_literal: true

class Character < ApplicationRecord
  MAX_NAME_LENGTH = 30
  GAMEPLAY_CONTEXT_KEY = "gameplay_context"
  GAMEPLAY_CONTEXTS = %w[world shop city_building world_location arena_room airship].freeze

  PRIMARY_STATS = %i[strength dexterity luck vitality intelligence].freeze
  BASE_PRIMARY_STATS = PRIMARY_STATS.index_with { 1 }.freeze
  HP_PER_HEALTH = 5
  MP_PER_KNOWLEDGE = 7
  MASS_PER_STRENGTH = 5
  MASS_PER_HEALTH = 10
  MASS_PER_LEVEL = 10
  BASE_ACTION_POINTS = 80
  ACTION_POINT_LEVEL_BONUSES = {5 => 10, 10 => 10}.freeze
  STAT_LABELS = {
    strength: "Strength",
    dexterity: "Dexterity",
    luck: "Luck",
    vitality: "Health",
    intelligence: "Knowledge"
  }.freeze
  STAT_ALIASES = {
    "strength" => :strength,
    "dexterity" => :dexterity,
    "luck" => :luck,
    "intelligence" => :intelligence,
    "knowledge" => :intelligence,
    "vitality" => :vitality,
    "health" => :vitality
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
    "none" => "None",
    "law" => "Law",
    "light" => "Light",
    "balance" => "Balance",
    "chaos" => "Chaos",
    "dark" => "Dark"
  }.freeze

  EQUIPMENT_STAT_ALIASES = {
    "strength" => :strength,
    "dexterity" => :dexterity,
    "luck" => :luck,
    "intelligence" => :intelligence,
    "knowledge" => :intelligence,
    "vitality" => :vitality,
    "health" => :vitality
  }.freeze
  EQUIPMENT_SKILL_ALIASES = {
    "unarmed_skill" => :unarmed_combat,
    "unarmed_combat" => :unarmed_combat,
    "sword_skill" => :sword_mastery,
    "sword_mastery" => :sword_mastery,
    "axe_skill" => :axe_mastery,
    "axe_mastery" => :axe_mastery,
    "blunt_skill" => :bludgeoning_mastery,
    "bludgeoning_skill" => :bludgeoning_mastery,
    "bludgeoning_mastery" => :bludgeoning_mastery,
    "knife_skill" => :knife_mastery,
    "knife_mastery" => :knife_mastery,
    "throwing_skill" => :throwing_mastery,
    "throwing_mastery" => :throwing_mastery,
    "polearm_skill" => :polearm_mastery,
    "polearm_mastery" => :polearm_mastery,
    "staff_skill" => :staff_mastery,
    "staff_mastery" => :staff_mastery,
    "two_handed_skill" => :two_handed_mastery,
    "two_handed_mastery" => :two_handed_mastery,
    "dual_wield_skill" => :dual_wielding,
    "dual_wielding" => :dual_wielding
  }.freeze

  belongs_to :user

  has_one :position, class_name: "CharacterPosition", dependent: :destroy
  has_one :inventory, dependent: :destroy
  has_many :character_licenses, dependent: :destroy
  has_many :character_injuries, dependent: :restrict_with_error
  has_many :active_injuries, -> { active_at(Time.current) }, class_name: "CharacterInjury"
  has_many :arena_applications, foreign_key: :applicant_id, dependent: :destroy
  has_many :arena_application_memberships, dependent: :destroy

  has_many :arena_participations, dependent: :destroy

  has_many :movement_commands, dependent: :destroy
  has_many :airship_journeys, dependent: :destroy
  has_many :world_action_offers, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: {maximum: MAX_NAME_LENGTH}
  validates :level, numericality: {greater_than_or_equal_to: 0}
  validates :experience, numericality: {greater_than_or_equal_to: 0}
  validates :stat_points_available, numericality: {greater_than_or_equal_to: 0}
  validates :combat_skill_points, :peace_skill_points, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validates :perk_points, numericality: {greater_than_or_equal_to: 0}
  validates :fatigue_percent, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}
  validates :alignment, inclusion: {in: ALIGNMENTS.values}

  validate :respect_character_limit, on: :create

  after_create :ensure_inventory!

  # An open owned offer or joined group place reserves this character.
  def waiting_arena_application
    ArenaApplication.open.where(applicant_id: id).or(
      ArenaApplication.open.where(id: arena_application_memberships.select(:arena_application_id))
    ).first
  end

  # Each player acknowledges a physical Arena/scroll result independently. Reloads
  # and a fresh login must retain this screen after another player ends a fight.
  def unfinished_arena_result
    arena_participations.joins(:arena_match).merge(ArenaMatch.completed)
      .where("arena_matches.metadata @> ?", {physical_only: true}.to_json)
      .where("NULLIF(arena_participations.metadata ->> 'finished_at', '') IS NULL")
      .order("arena_matches.ended_at DESC NULLS LAST", id: :desc).first&.arena_match
  end

  # Query fresh state: boarding and disembarkation can happen in another tab.
  def active_airship_journey
    airship_journeys.aboard.first
  end

  def gameplay_context
    payload = metadata.to_h[GAMEPLAY_CONTEXT_KEY]
    return {"name" => "world", "params" => {}} unless payload.is_a?(Hash)

    normalized = payload.deep_stringify_keys
    return {"name" => "world", "params" => {}} unless GAMEPLAY_CONTEXTS.include?(normalized["name"])
    return {"name" => "world", "params" => {}} unless normalized["params"].is_a?(Hash)

    normalized.slice("name", "params")
  end

  # Save the allowlisted gameplay surface and any resulting local-chat room
  # entry together. Reloading an unchanged surface preserves its entry time.
  def remember_gameplay_context!(name:, params: {})
    normalized_name = name.to_s
    raise ArgumentError, "Unsupported gameplay context" unless GAMEPLAY_CONTEXTS.include?(normalized_name)
    raise ArgumentError, "Gameplay context params must be an object" unless params.is_a?(Hash)

    payload = {
      "name" => normalized_name,
      "params" => params.to_h.deep_stringify_keys
    }

    with_lock do
      reload
      unless gameplay_context == payload
        update!(metadata: metadata.to_h.merge(GAMEPLAY_CONTEXT_KEY => payload))
      end
      Chat::LocalContext.new(character: self).synchronize!
    end

    payload
  end

  def stats
    base = BASE_PRIMARY_STATS.dup
    allocated_stats.each do |stat, value|
      key = self.class.normalize_stat_key(stat)
      next unless key

      base[key] = base.fetch(key, 0) + value.to_i
    end
    base[:strength] += level.to_i / 2 if owns_perk?(:more_strength)
    equipment_stat_modifiers.each do |stat, value|
      base[stat] = base.fetch(stat, 0) + value.to_i
    end
    penalty = active_injuries.select(&:active?).sum(&:stat_penalty_percent).clamp(0, 90)
    base.transform_values! { |value| [(value * (100 - penalty) / 100.0).floor, 1].max } if penalty.positive?
    Game::Systems::StatBlock.new(base:)
  end

  def self.normalize_stat_key(key)
    STAT_ALIASES[key.to_s.strip.downcase.tr(" -", "_")]
  end

  def self.stat_label(key)
    STAT_LABELS.fetch(key.to_sym)
  end

  def self.xp_required_for_level(level)
    Game::Progression::Catalog.experience_threshold_to_reach(level)
  end

  def experience_to_next_level
    threshold = self.class.xp_required_for_level(level + 1)
    return 0 unless threshold

    [threshold - experience.to_i, 0].max
  end

  # Returns read-only combat limits evaluated at the supplied server Time.
  # Only trusted server metadata may populate combat_entitlement with a tier
  # and ISO8601 expires_at timestamp (including an explicit timezone). Missing,
  # malformed, unknown, or expired entitlements receive standard limits. This
  # method neither persists entitlement state nor accepts client capabilities.
  def combat_benefits(now: Time.current)
    entitlement = metadata.is_a?(Hash) ? metadata["combat_entitlement"] : nil
    entitlement = {} unless entitlement.is_a?(Hash)
    timestamp = entitlement["expires_at"]
    expires_at = begin
      if timestamp.is_a?(String) && timestamp.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/)
        DateTime.iso8601(timestamp).to_time
      end
    rescue ArgumentError
      nil
    end

    Game::Combat::PremiumBenefits.new(tier: entitlement["tier"], expires_at: expires_at, now: now)
  end

  # Neverlands derives base hit points, mana, and carried mass directly from
  # primary stats. Equipment bonuses stay separate from these persisted base
  # values so allocating a stat cannot refill an injured character.
  def derived_base_max_hp
    base_primary_stat_value(:vitality) * HP_PER_HEALTH
  end

  def derived_base_max_mp
    base_primary_stat_value(:intelligence) * MP_PER_KNOWLEDGE
  end

  def carrying_capacity
    current_stats = stats
    (current_stats.get(:strength).to_i * MASS_PER_STRENGTH) +
      (current_stats.get(:vitality).to_i * MASS_PER_HEALTH) +
      (level.to_i * MASS_PER_LEVEL)
  end

  def assign_base_vitals_from_stats
    self.max_hp = derived_base_max_hp
    self.max_mp = derived_base_max_mp
    self.current_hp = [current_hp.to_i, max_hp].min
    self.current_mp = [current_mp.to_i, max_mp].min
  end

  def base_primary_stat_value(stat_key)
    normalized = self.class.normalize_stat_key(stat_key)
    return 0 unless normalized

    BASE_PRIMARY_STATS.fetch(normalized) + allocated_stats.to_h.sum do |key, value|
      (self.class.normalize_stat_key(key) == normalized) ? value.to_i : 0
    end
  end

  # Neverlands grants an 80 AP base, adds 10 AP at levels 5 and 10, and adds
  # the effective Extra Action Points skill one-for-one. Temporary fight
  # effects remain per-participation combat-profile inputs.
  def max_action_points
    level_bonus = ACTION_POINT_LEVEL_BONUSES.sum do |minimum_level, bonus|
      level.to_i >= minimum_level ? bonus : 0
    end

    BASE_ACTION_POINTS + level_bonus + passive_skill_level(:extra_action_points)
  end

  def alignment_label
    ALIGNMENT_LABELS.fetch(alignment, "None")
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

  # Read the saved skill plus usable equipment bonuses exactly once. The
  # allocation cap is 100; captured effective weapon mastery reaches 130/150.
  #
  # @param skill_key [Symbol, String] the skill identifier (e.g., :wanderer)
  # @return [Integer] effective skill level, which may exceed 100
  def passive_skill_level(skill_key)
    base_passive_skill_level(skill_key) + equipment_skill_bonus(skill_key)
  end

  # Profession counters are separate from spendable Skills and boolean Perks.
  # Missing/malformed counters contribute zero; Doctor equipment adds flat points
  # as published by Neverlands. No passive-skill allocation cap applies.
  def doctor_proficiency
    counters = metadata.to_h["profession_skills"]
    value = counters["doctor"] if counters.is_a?(Hash)
    base = value.is_a?(Integer) && value >= 0 ? value : 0
    [base + equipment_skill_bonus(:doctor), 0].max
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

  # Increase the saved skill, retaining the allocation cap and never persisting
  # temporary equipment bonuses as learned levels.
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @param amount [Integer] amount to increase (default 1)
  def increase_passive_skill!(skill_key, amount = 1)
    current = base_passive_skill_level(skill_key)
    set_passive_skill!(skill_key, current + amount)
  end

  # Spend a skill point on a skill using tiered progression
  # Returns the new saved level; equipment affects neither tiers nor eligibility.
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
  # @param base_level [Integer] the saved level before this session's allocations,
  #   excluding equipment bonuses
  # @return [Integer, nil] new skill level, or nil if cannot refund
  def refund_skill_point!(skill_key, base_level:)
    key = skill_key.to_sym
    definition = Game::Skills::PassiveSkillRegistry.find(key)
    return nil unless definition

    current_level = base_passive_skill_level(key)
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

  # Preview the captured tier gain from the saved level, excluding equipment.
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] points that would be gained on next spend
  def skill_points_per_spend(skill_key)
    definition = Game::Skills::PassiveSkillRegistry.find(skill_key.to_sym)
    return 0 unless definition

    current_level = base_passive_skill_level(skill_key)
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

  def owns_perk?(perk_key)
    perks.to_h[perk_key.to_s] == true
  end

  def owned_perk_keys
    Game::Skills::PerkRegistry.all_keys.select { |key| owns_perk?(key) }
  end

  def award_perk_points!(amount = 1)
    points = amount.to_i
    return if points <= 0

    increment!(:perk_points, points)
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

  WEAPON_MASTERY_KEYS = {
    "knife" => :knife_mastery, "sword" => :sword_mastery,
    "axe" => :axe_mastery, "blunt" => :bludgeoning_mastery,
    "polearm" => :polearm_mastery, "staff" => :staff_mastery,
    "throwing" => :throwing_mastery, "exotic" => :exotic_weapon_mastery
  }.freeze

  # Usable weapon effects select mastery; shield and broken items never do.
  def combat_weapon
    combat_weapons.first
  end

  def combat_weapons
    return [] unless inventory

    inventory.inventory_items.equipped.includes(:item_template).select do |item|
      !item.broken? && WEAPON_MASTERY_KEYS.key?(item.effect_modifiers["weapon_family"])
    end
  end

  def weapon_mastery
    weapons = combat_weapons
    return passive_skill_level(:unarmed_combat) if weapons.empty?

    weapons.sum { |item| weapon_mastery_for(item) }.to_f / weapons.size
  end

  def weapon_mastery_for(item)
    passive_skill_level(WEAPON_MASTERY_KEYS.fetch(item.effect_modifiers["weapon_family"], :unarmed_combat))
  end

  def equipped_weapon_damage
    return 0 unless inventory

    inventory.inventory_items.equipped.includes(:item_template).sum do |item|
      item.broken? ? 0 : weapon_damage_average(item.effect_modifiers)
    end
  end

  # Unmitigated physical damage input; the opponent and selected action govern
  # final damage/chances in the shared resolver.
  def attack_power
    Game::Combat::Calibration.attack(Arena::CombatAttributes.for_character(self)).round
  end

  def defense
    armor_class
  end

  def critical_chance
    Arena::CombatResolver::BASE_CRIT_CHANCE
  end

  def effective_max_hp
    read_attribute(:max_hp).to_i + equipment_effect_value("hp", "max_hp").to_i
  end

  # Total usable item armor across the supported defense/armor/armor_class
  # aliases. Primary stats and the inherited defense formula are separate.
  # @return [Numeric] equipped armor class
  def armor_class
    equipment_defense_bonus
  end

  def armor_pierce_percent
    equipment_effect_value("armor_pierce", "armor_piercing")
  end

  # Source Crushing modifier; displayed percent units are not a crit probability.
  # @return [Numeric] equipped Crushing, independent of weapon mastery
  def crushing_percent
    equipment_effect_value("crushing")
  end

  # Source anti-critical modifier, independent of physical damage resistance.
  # This accessor supplies an input, not an inferred chance or damage reduction.
  # @return [Numeric] equipped Fortitude in displayed percent units
  def fortitude_percent
    equipment_effect_value("fortitude")
  end

  # @return [Numeric] equipped Accuracy modifier, separate from Dexterity/Luck
  def accuracy_bonus
    equipment_effect_value("accuracy")
  end

  # @return [Numeric] equipped Evasion modifier, including the legacy dodge alias
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
    attributes = Arena::CombatAttributes.for_character(self)
    {
      attack_power: {strength: attributes[:strength] * Game::Combat::Calibration.config.fetch("strength_damage"),
                     equipment: attributes[:weapon_damage], mastery: attributes[:mastery], total: attack_power},
      defense: {equipment: armor_class, total: defense},
      critical_chance: {base: critical_chance, total: critical_chance},
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

  # Get agility used by the shared hit, dodge, and block resolver.
  #
  # @return [Integer] agility value
  def agility
    stats.get(:dexterity).to_i
  end

  # ===================
  # Mana System
  # ===================

  # Calculate effective maximum MP.
  # Neverlands exposes `Fast Mana Regeneration` as an allocatable skill, but the
  # exact MP max/cost formulas are not source-captured yet.
  #
  # @return [Integer] effective maximum mana points
  def effective_max_mp
    (read_attribute(:max_mp) || 50).to_i + equipment_effect_value("mp", "mana", "max_mp").to_i
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

  # Sum flat and nested skill bonuses from usable equipment. Canonical registry
  # keys and captured weapon-skill aliases share the same interpretation;
  # primary stats, combat modifiers and unknown keys never become skill levels.
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] total skill bonus from equipment
  def equipment_skill_bonus(skill_key)
    return 0 unless inventory

    key = skill_key.to_s
    normalized_key = normalize_equipment_effect_key(key)
    return 0 unless normalized_key == "doctor" || Game::Skills::PassiveSkillRegistry.find(normalized_key)

    inventory.inventory_items.equipped.includes(:item_template).sum do |item|
      next 0 if item.broken? || (normalized_key == "doctor" && item.expired?)

      effects = item.effect_modifiers.to_h
      skill_mods = effects["skill_bonuses"] || effects[:skill_bonuses] || {}
      nested_bonus = if skill_mods.is_a?(Hash)
        skill_mods.sum do |effect_key, value|
          mapped = EQUIPMENT_SKILL_ALIASES.fetch(normalize_equipment_effect_key(effect_key), normalize_equipment_effect_key(effect_key).to_sym)
          mapped.to_s == normalized_key ? numeric_equipment_effect(value).to_i : 0
        end
      else
        0
      end

      direct_bonus = effects.sum do |effect_key, value|
        mapped = EQUIPMENT_SKILL_ALIASES.fetch(normalize_equipment_effect_key(effect_key), normalize_equipment_effect_key(effect_key).to_sym)
        mapped.to_s == normalized_key ? numeric_equipment_effect(value).to_i : 0
      end

      nested_bonus + direct_bonus
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

  # Compatibility reader for the same effective total as passive_skill_level.
  # Equipment is already included there and must not be added a second time.
  #
  # @param skill_key [Symbol, String] the skill identifier
  # @return [Integer] effective skill level, which may exceed 100
  def effective_passive_skill_level(skill_key)
    passive_skill_level(skill_key)
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
    create_inventory!(slot_capacity: 30, weight_capacity: carrying_capacity) unless inventory
  end
end
