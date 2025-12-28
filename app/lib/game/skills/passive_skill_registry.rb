# frozen_string_literal: true

module Game
  module Skills
    # PassiveSkillRegistry defines all available passive skills and their effects.
    #
    # Passive skills are abilities that:
    # - Level from 0 to 100
    # - Provide ongoing bonuses/modifiers
    # - Use tiered progression (more points at low levels, fewer at high)
    #
    # Purpose:
    #   Central registry for passive skill definitions. Each skill defines its
    #   key, name, description, max level, category, effect calculation, and
    #   progression rate for tiered leveling.
    #
    # Inputs:
    #   - skill_key: Symbol key identifying the skill (e.g., :wanderer)
    #
    # Returns:
    #   Skill definition hash with all configuration
    #
    # Usage:
    #   definition = Game::Skills::PassiveSkillRegistry.find(:wanderer)
    #   # => { key: :wanderer, name: "Wanderer", max_level: 100, ... }
    #
    #   Game::Skills::PassiveSkillRegistry.all_keys
    #   # => [:wanderer, :endurance, ...]
    #
    #   Game::Skills::PassiveSkillRegistry.by_category(:combat)
    #   # => [{ key: :melee_combat, ... }, ...]
    #
    class PassiveSkillRegistry
      MAX_LEVEL = 100

      # Skill pool types - determines which skill point pool is used
      POOL_COMBAT = :combat   # Combat/Magic/Resistance skills
      POOL_PEACE = :peace     # Peace/Crafting skills

      # Skill definitions with their effects and formulas
      # Each skill has:
      #   - key: unique identifier
      #   - name: display name
      #   - description: what the skill does
      #   - max_level: maximum level (default 100)
      #   - category: grouping for UI (combat, magic, resistance, peace)
      #   - pool: which skill point pool to use (:combat or :peace)
      #   - effect_type: what game mechanic this affects
      #   - effect_formula: lambda that calculates the effect value
      #   - progression_rate: tiered progression "tier0:tier1:tier2:tier3"
      #   - prerequisites: optional hash of {skill_key => required_level} or
      #                    array of [{skill_key => level}, ...] for OR conditions
      #
      SKILLS = {
        # ==========================================
        # COMBAT SKILLS (use combat_skill_points)
        # ==========================================
        melee_combat: {
          key: :melee_combat,
          name: "Melee Combat",
          description: "Increases damage dealt with melee weapons (swords, axes, maces).",
          max_level: MAX_LEVEL,
          category: :combat,
          pool: POOL_COMBAT,
          effect_type: :melee_damage_bonus,
          # At max level: +50% melee damage
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 },
          progression_rate: "10:8:6:4"
        },

        ranged_combat: {
          key: :ranged_combat,
          name: "Ranged Combat",
          description: "Increases damage dealt with ranged weapons (bows, crossbows, thrown).",
          max_level: MAX_LEVEL,
          category: :combat,
          pool: POOL_COMBAT,
          effect_type: :ranged_damage_bonus,
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 },
          progression_rate: "10:8:6:4"
        },

        unarmed_combat: {
          key: :unarmed_combat,
          name: "Unarmed Combat",
          description: "Increases damage dealt with bare hands and hand wraps.",
          max_level: MAX_LEVEL,
          category: :combat,
          pool: POOL_COMBAT,
          effect_type: :unarmed_damage_bonus,
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 },
          progression_rate: "8:6:4:2"
        },

        critical_strikes: {
          key: :critical_strikes,
          name: "Critical Strikes",
          description: "Increases critical hit chance in combat. Requires Melee Combat 30 or Ranged Combat 30.",
          max_level: MAX_LEVEL,
          category: :combat,
          pool: POOL_COMBAT,
          effect_type: :crit_chance_bonus,
          # At max level: +15% crit chance
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.15 },
          progression_rate: "6:4:4:2",
          # OR condition: need either melee or ranged at 30
          prerequisites: [{melee_combat: 30}, {ranged_combat: 30}]
        },

        evasion: {
          key: :evasion,
          name: "Evasion",
          description: "Increases chance to dodge incoming attacks.",
          max_level: MAX_LEVEL,
          category: :combat,
          pool: POOL_COMBAT,
          effect_type: :dodge_chance_bonus,
          # At max level: +20% dodge chance
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.20 },
          progression_rate: "8:6:4:2"
        },

        block_mastery: {
          key: :block_mastery,
          name: "Block Mastery",
          description: "Increases damage blocked when defending. Requires Evasion 20.",
          max_level: MAX_LEVEL,
          category: :combat,
          pool: POOL_COMBAT,
          effect_type: :block_bonus,
          # At max level: +40% block effectiveness
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.40 },
          progression_rate: "8:6:4:2",
          prerequisites: {evasion: 20}
        },

        # ==========================================
        # MAGIC SKILLS (use combat_skill_points)
        # ==========================================
        elemental_magic: {
          key: :elemental_magic,
          name: "Elemental Magic",
          description: "Increases damage from fire, ice, and lightning spells.",
          max_level: MAX_LEVEL,
          category: :magic,
          pool: POOL_COMBAT,
          effect_type: :elemental_damage_bonus,
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 },
          progression_rate: "8:6:4:2"
        },

        healing_arts: {
          key: :healing_arts,
          name: "Healing Arts",
          description: "Increases effectiveness of healing spells and potions. Requires Elemental Magic 30.",
          max_level: MAX_LEVEL,
          category: :magic,
          pool: POOL_COMBAT,
          effect_type: :healing_bonus,
          # At max level: +40% healing effectiveness
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.40 },
          progression_rate: "8:6:4:2",
          prerequisites: {elemental_magic: 30}
        },

        arcane_power: {
          key: :arcane_power,
          name: "Arcane Power",
          description: "Increases maximum mana and mana regeneration rate.",
          max_level: MAX_LEVEL,
          category: :magic,
          pool: POOL_COMBAT,
          effect_type: :mana_bonus,
          # At max level: +30% max mana
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.30 },
          progression_rate: "6:4:4:2"
        },

        spell_mastery: {
          key: :spell_mastery,
          name: "Spell Mastery",
          description: "Reduces mana cost of all spells. Requires Arcane Power 20.",
          max_level: MAX_LEVEL,
          category: :magic,
          pool: POOL_COMBAT,
          effect_type: :mana_cost_reduction,
          # At max level: -25% mana cost
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.25 },
          progression_rate: "6:4:4:2",
          prerequisites: {arcane_power: 20}
        },

        # ==========================================
        # RESISTANCE SKILLS (use combat_skill_points)
        # ==========================================
        fire_resistance: {
          key: :fire_resistance,
          name: "Fire Resistance",
          description: "Reduces damage taken from fire attacks.",
          max_level: MAX_LEVEL,
          category: :resistance,
          pool: POOL_COMBAT,
          effect_type: :fire_resist,
          # At max level: 40% fire damage reduction
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.40 },
          progression_rate: "6:4:4:2"
        },

        cold_resistance: {
          key: :cold_resistance,
          name: "Cold Resistance",
          description: "Reduces damage taken from ice and cold attacks.",
          max_level: MAX_LEVEL,
          category: :resistance,
          pool: POOL_COMBAT,
          effect_type: :cold_resist,
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.40 },
          progression_rate: "6:4:4:2"
        },

        lightning_resistance: {
          key: :lightning_resistance,
          name: "Lightning Resistance",
          description: "Reduces damage taken from lightning attacks.",
          max_level: MAX_LEVEL,
          category: :resistance,
          pool: POOL_COMBAT,
          effect_type: :lightning_resist,
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.40 },
          progression_rate: "6:4:4:2"
        },

        physical_fortitude: {
          key: :physical_fortitude,
          name: "Physical Fortitude",
          description: "Reduces physical damage taken from all sources.",
          max_level: MAX_LEVEL,
          category: :resistance,
          pool: POOL_COMBAT,
          effect_type: :physical_resist,
          # At max level: 25% physical damage reduction
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.25 },
          progression_rate: "4:4:2:2"
        },

        # ==========================================
        # SURVIVAL/EXPLORATION (use combat_skill_points)
        # ==========================================
        wanderer: {
          key: :wanderer,
          name: "Wanderer",
          description: "Increases movement speed on the world map. Reduces travel time between tiles.",
          max_level: MAX_LEVEL,
          category: :survival,
          pool: POOL_COMBAT,
          effect_type: :movement_cooldown_reduction,
          # Formula: At level 0 = 0% reduction, at level 100 = 70% reduction
          # This means: 10s base * (1 - 0.70) = 3s at max level
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.70 },
          progression_rate: "10:8:6:4"
        },

        endurance: {
          key: :endurance,
          name: "Endurance",
          description: "Increases maximum HP and HP regeneration rate.",
          max_level: MAX_LEVEL,
          category: :survival,
          pool: POOL_COMBAT,
          effect_type: :hp_bonus,
          # At max level: +50% HP
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 },
          progression_rate: "8:6:4:2"
        },

        perception: {
          key: :perception,
          name: "Perception",
          description: "Increases chance to find rare resources and hidden paths.",
          max_level: MAX_LEVEL,
          category: :survival,
          pool: POOL_COMBAT,
          effect_type: :discovery_bonus,
          # At max level: +30% discovery chance
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.30 },
          progression_rate: "6:4:4:2"
        },

        luck: {
          key: :luck,
          name: "Luck",
          description: "Increases gold drops and rare item find chance.",
          max_level: MAX_LEVEL,
          category: :survival,
          pool: POOL_COMBAT,
          effect_type: :luck_bonus,
          # At max level: +25% gold and loot bonus
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.25 },
          progression_rate: "4:4:2:2"
        },

        # ==========================================
        # PEACE SKILLS (use peace_skill_points)
        # ==========================================
        herbalism: {
          key: :herbalism,
          name: "Herbalism",
          description: "Increases yield and quality of gathered herbs and plants.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :herb_gathering_bonus,
          # At max level: +100% herb yield
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 1.0 },
          progression_rate: "2:2:2:2"
        },

        mining: {
          key: :mining,
          name: "Mining",
          description: "Increases yield and quality of mined ores and gems.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :mining_bonus,
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 1.0 },
          progression_rate: "2:2:2:2"
        },

        fishing: {
          key: :fishing,
          name: "Fishing",
          description: "Increases catch rate and chance for rare fish.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :fishing_bonus,
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 1.0 },
          progression_rate: "2:2:2:2"
        },

        blacksmithing: {
          key: :blacksmithing,
          name: "Blacksmithing",
          description: "Unlocks higher tier crafting recipes for weapons and armor.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :crafting_tier,
          # Tier unlocks at 25, 50, 75, 100
          effect_formula: ->(level) { (level / 25).floor },
          progression_rate: "2:2:2:2"
        },

        alchemy: {
          key: :alchemy,
          name: "Alchemy",
          description: "Increases potion effectiveness and unlocks advanced recipes.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :alchemy_bonus,
          # At max level: +50% potion effectiveness
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 },
          progression_rate: "2:2:2:2"
        },

        cooking: {
          key: :cooking,
          name: "Cooking",
          description: "Increases food buff duration and unlocks advanced recipes.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :cooking_bonus,
          # At max level: +100% food buff duration
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 1.0 },
          progression_rate: "2:2:2:2"
        },

        first_aid: {
          key: :first_aid,
          name: "First Aid",
          description: "Increases out-of-combat HP regeneration and bandage effectiveness.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :regen_bonus,
          # At max level: +75% out-of-combat regen
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.75 },
          progression_rate: "2:2:2:2"
        },

        trading: {
          key: :trading,
          name: "Trading",
          description: "Improves prices when buying and selling with NPCs.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :trade_bonus,
          # At max level: 20% better prices
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.20 },
          progression_rate: "2:2:2:2"
        },

        animal_handling: {
          key: :animal_handling,
          name: "Animal Handling",
          description: "Improves mount speed and unlocks mount taming.",
          max_level: MAX_LEVEL,
          category: :peace,
          pool: POOL_PEACE,
          effect_type: :mount_bonus,
          # At max level: +30% mount speed
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.30 },
          progression_rate: "2:2:2:2"
        }
      }.freeze

      # Category display order and labels
      CATEGORIES = {
        combat: {name: "Combat Skills", pool: POOL_COMBAT},
        magic: {name: "Magic Skills", pool: POOL_COMBAT},
        resistance: {name: "Resistances", pool: POOL_COMBAT},
        survival: {name: "Survival & Exploration", pool: POOL_COMBAT},
        peace: {name: "Peace Skills", pool: POOL_PEACE}
      }.freeze

      class << self
        # Find a skill definition by key
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Hash, nil] skill definition or nil if not found
        def find(skill_key)
          SKILLS[skill_key.to_sym]
        end

        # Get all registered skill keys
        #
        # @return [Array<Symbol>] list of all skill keys
        def all_keys
          SKILLS.keys
        end

        # Get all skill definitions
        #
        # @return [Hash] all skill definitions
        def all
          SKILLS
        end

        # Get skills by category
        #
        # @param category [Symbol] the category to filter by
        # @return [Array<Hash>] skills in that category
        def by_category(category)
          SKILLS.values.select { |skill| skill[:category] == category.to_sym }
        end

        # Get skills by pool type
        #
        # @param pool [Symbol] :combat or :peace
        # @return [Array<Hash>] skills using that pool
        def by_pool(pool)
          SKILLS.values.select { |skill| skill[:pool] == pool.to_sym }
        end

        # Check if a skill key is valid
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Boolean] true if skill exists
        def valid?(skill_key)
          SKILLS.key?(skill_key.to_sym)
        end

        # Calculate the effect value for a skill at a given level
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @param level [Integer] the skill level (0-100)
        # @return [Float] the calculated effect value
        def calculate_effect(skill_key, level)
          definition = find(skill_key)
          return 0.0 unless definition

          clamped_level = level.to_i.clamp(0, definition[:max_level])
          definition[:effect_formula].call(clamped_level)
        end

        # Get the max level for a skill
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Integer] max level (default 100)
        def max_level(skill_key)
          find(skill_key)&.dig(:max_level) || MAX_LEVEL
        end

        # Get the progression rate for a skill
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [String] progression rate string (e.g., "10:8:6:4")
        def progression_rate(skill_key)
          find(skill_key)&.dig(:progression_rate) || "8:6:4:2"
        end

        # Get the pool type for a skill
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Symbol] :combat or :peace
        def pool_for(skill_key)
          find(skill_key)&.dig(:pool) || POOL_COMBAT
        end

        # Get all category definitions
        #
        # @return [Hash] category definitions with names and pools
        def categories
          CATEGORIES
        end

        # Get skill keys grouped by category
        #
        # @return [Hash<Symbol, Array<Symbol>>] category => [skill_keys]
        def grouped_by_category
          SKILLS.values.group_by { |s| s[:category] }.transform_values { |skills| skills.map { |s| s[:key] } }
        end

        # Get prerequisites for a skill
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Hash, Array, nil] prerequisites definition
        def prerequisites(skill_key)
          find(skill_key)&.dig(:prerequisites)
        end

        # Check if prerequisites are met for a skill
        #
        # @param skill_key [Symbol, String] the skill to check
        # @param character [Character] the character to check against
        # @return [Hash] { met: Boolean, missing: Array of {skill:, required:, current:} }
        def prerequisites_met?(skill_key, character)
          prereqs = prerequisites(skill_key)
          return {met: true, missing: []} if prereqs.nil?

          missing = []

          case prereqs
          when Hash
            # AND condition: all prerequisites must be met
            prereqs.each do |prereq_skill, required_level|
              current_level = character.passive_skill_level(prereq_skill)
              if current_level < required_level
                missing << {
                  skill: prereq_skill,
                  required: required_level,
                  current: current_level
                }
              end
            end
          when Array
            # OR condition: at least one set of prerequisites must be met
            any_met = prereqs.any? do |prereq_set|
              prereq_set.all? do |prereq_skill, required_level|
                character.passive_skill_level(prereq_skill) >= required_level
              end
            end

            unless any_met
              # Show all possible options as missing
              prereqs.each do |prereq_set|
                prereq_set.each do |prereq_skill, required_level|
                  current_level = character.passive_skill_level(prereq_skill)
                  missing << {
                    skill: prereq_skill,
                    required: required_level,
                    current: current_level,
                    is_or_condition: true
                  }
                end
              end
            end
          end

          {met: missing.empty?, missing: missing}
        end

        # Check if a character can spend points on a skill
        #
        # @param skill_key [Symbol, String] the skill to check
        # @param character [Character] the character to check
        # @return [Hash] { allowed: Boolean, reason: String }
        def can_spend?(skill_key, character)
          skill = find(skill_key)
          return {allowed: false, reason: "Skill not found"} unless skill

          # Check skill points
          pool = skill[:pool]
          available = character.available_skill_points_for_pool(pool)
          return {allowed: false, reason: "No #{pool} skill points available"} if available <= 0

          # Check current level
          current_level = character.passive_skill_level(skill_key)
          max = skill[:max_level] || MAX_LEVEL
          return {allowed: false, reason: "Skill is at maximum level"} if current_level >= max

          # Check prerequisites
          prereq_result = prerequisites_met?(skill_key, character)
          unless prereq_result[:met]
            missing_text = prereq_result[:missing].map do |m|
              "#{m[:skill].to_s.titleize} #{m[:required]}"
            end.join(" or ")
            return {allowed: false, reason: "Requires: #{missing_text}"}
          end

          {allowed: true, reason: nil}
        end

        # Get all skills available for a character (prerequisites met)
        #
        # @param character [Character] the character to check
        # @return [Array<Symbol>] skill keys that can be leveled
        def available_for(character)
          SKILLS.keys.select do |skill_key|
            result = can_spend?(skill_key, character)
            result[:allowed]
          end
        end

        # Get skills locked by prerequisites for a character
        #
        # @param character [Character] the character to check
        # @return [Array<Hash>] array of {skill:, prerequisites:, missing:}
        def locked_skills_for(character)
          SKILLS.map do |key, skill|
            prereqs = skill[:prerequisites]
            next nil if prereqs.nil?

            prereq_result = prerequisites_met?(key, character)
            next nil if prereq_result[:met]

            {
              skill: key,
              name: skill[:name],
              prerequisites: prereqs,
              missing: prereq_result[:missing]
            }
          end.compact
        end
      end
    end
  end
end
