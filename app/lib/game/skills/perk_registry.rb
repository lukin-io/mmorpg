# frozen_string_literal: true

module Game
  module Skills
    # PerkRegistry defines all available perks with their effects and mutual exclusions.
    #
    # Perks are permanent character bonuses that:
    # - Are unlocked with perk points (gained every 5 levels)
    # - Have mutual exclusions (selecting one may disable others)
    # - Provide unique combat or gameplay effects
    #
    # Purpose:
    #   Central registry for perk definitions. Each perk defines its key, name,
    #   description, effects, requirements, and mutual exclusions.
    #
    # Inputs:
    #   - perk_key: Symbol key identifying the perk (e.g., :berserker)
    #
    # Returns:
    #   Perk definition hash with all configuration
    #
    # Usage:
    #   definition = Game::Skills::PerkRegistry.find(:berserker)
    #   # => { key: :berserker, name: "Berserker", excludes: [:guardian, :tactician], ... }
    #
    #   Game::Skills::PerkRegistry.available_for(character)
    #   # => Array of perks the character can select
    #
    class PerkRegistry
      PERK_POINTS_PER_LEVEL_INTERVAL = 5  # Earn 1 perk point every 5 levels

      # Perk definitions grouped by category
      # Each perk has:
      #   - key: unique identifier
      #   - name: display name
      #   - description: what the perk does
      #   - category: grouping (combat, magic, defense, utility)
      #   - level_required: minimum character level
      #   - effects: hash of stat/mechanic modifiers
      #   - excludes: array of mutually exclusive perk keys
      #
      PERKS = {
        # ==========================================
        # COMBAT PERKS
        # ==========================================
        berserker: {
          key: :berserker,
          name: "Berserker",
          description: "Deal +25% damage when below 30% HP. -10% defense at all times.",
          category: :combat,
          level_required: 5,
          effects: {
            low_hp_damage_bonus: 0.25,
            low_hp_threshold: 0.30,
            defense_penalty: 0.10
          },
          excludes: %i[guardian tactician]
        },

        guardian: {
          key: :guardian,
          name: "Guardian",
          description: "+20% defense and block effectiveness. -15% attack damage.",
          category: :combat,
          level_required: 5,
          effects: {
            defense_bonus: 0.20,
            block_bonus: 0.20,
            attack_penalty: 0.15
          },
          excludes: %i[berserker assassin]
        },

        assassin: {
          key: :assassin,
          name: "Assassin",
          description: "+30% critical damage. First attack each combat has +25% crit chance.",
          category: :combat,
          level_required: 10,
          effects: {
            critical_damage_bonus: 0.30,
            first_strike_crit_bonus: 0.25
          },
          excludes: %i[guardian juggernaut]
        },

        tactician: {
          key: :tactician,
          name: "Tactician",
          description: "+15% damage when attacking different body parts consecutively.",
          category: :combat,
          level_required: 10,
          effects: {
            varied_attack_bonus: 0.15
          },
          excludes: %i[berserker focused_striker]
        },

        focused_striker: {
          key: :focused_striker,
          name: "Focused Striker",
          description: "+20% damage when attacking the same body part twice in a row.",
          category: :combat,
          level_required: 10,
          effects: {
            same_target_bonus: 0.20
          },
          excludes: %i[tactician]
        },

        # ==========================================
        # MAGIC PERKS
        # ==========================================
        pyromancer: {
          key: :pyromancer,
          name: "Pyromancer",
          description: "+30% fire damage. +15% fire resistance.",
          category: :magic,
          level_required: 10,
          effects: {
            fire_damage_bonus: 0.30,
            fire_resistance_bonus: 0.15
          },
          excludes: %i[cryomancer stormcaller]
        },

        cryomancer: {
          key: :cryomancer,
          name: "Cryomancer",
          description: "+30% ice damage. +15% cold resistance. 10% chance to slow enemies.",
          category: :magic,
          level_required: 10,
          effects: {
            ice_damage_bonus: 0.30,
            cold_resistance_bonus: 0.15,
            slow_chance: 0.10
          },
          excludes: %i[pyromancer stormcaller]
        },

        stormcaller: {
          key: :stormcaller,
          name: "Stormcaller",
          description: "+30% lightning damage. +15% lightning resistance.",
          category: :magic,
          level_required: 10,
          effects: {
            lightning_damage_bonus: 0.30,
            lightning_resistance_bonus: 0.15
          },
          excludes: %i[pyromancer cryomancer]
        },

        battle_mage: {
          key: :battle_mage,
          name: "Battle Mage",
          description: "+15% spell damage. +10% melee damage. -20% max mana.",
          category: :magic,
          level_required: 15,
          effects: {
            spell_damage_bonus: 0.15,
            melee_damage_bonus: 0.10,
            max_mana_penalty: 0.20
          },
          excludes: %i[archmage]
        },

        archmage: {
          key: :archmage,
          name: "Archmage",
          description: "+25% spell damage. +30% max mana. -25% physical damage.",
          category: :magic,
          level_required: 15,
          effects: {
            spell_damage_bonus: 0.25,
            max_mana_bonus: 0.30,
            physical_damage_penalty: 0.25
          },
          excludes: %i[battle_mage juggernaut]
        },

        # ==========================================
        # DEFENSE PERKS
        # ==========================================
        juggernaut: {
          key: :juggernaut,
          name: "Juggernaut",
          description: "+15% HP. +10% all resistances. -20% dodge chance.",
          category: :defense,
          level_required: 10,
          effects: {
            hp_bonus: 0.15,
            all_resistance_bonus: 0.10,
            dodge_penalty: 0.20
          },
          excludes: %i[assassin archmage nimble]
        },

        nimble: {
          key: :nimble,
          name: "Nimble",
          description: "+20% dodge chance. +15% evasion skill effectiveness.",
          category: :defense,
          level_required: 10,
          effects: {
            dodge_bonus: 0.20,
            evasion_skill_bonus: 0.15
          },
          excludes: %i[juggernaut ironclad]
        },

        ironclad: {
          key: :ironclad,
          name: "Ironclad",
          description: "+25% armor. Block can reduce damage by 75% instead of 50%.",
          category: :defense,
          level_required: 15,
          effects: {
            armor_bonus: 0.25,
            block_max_reduction: 0.75
          },
          excludes: %i[nimble]
        },

        resilient: {
          key: :resilient,
          name: "Resilient",
          description: "Recover 5% HP at the start of each turn. -10% max HP.",
          category: :defense,
          level_required: 15,
          effects: {
            hp_regen_per_turn: 0.05,
            max_hp_penalty: 0.10
          },
          excludes: []
        },

        # ==========================================
        # UTILITY PERKS
        # ==========================================
        veteran: {
          key: :veteran,
          name: "Veteran",
          description: "+15% experience gained. +10% gold from combat.",
          category: :utility,
          level_required: 5,
          effects: {
            experience_bonus: 0.15,
            gold_bonus: 0.10
          },
          excludes: []
        },

        lucky: {
          key: :lucky,
          name: "Lucky",
          description: "+20% loot quality. +10% critical chance.",
          category: :utility,
          level_required: 10,
          effects: {
            loot_quality_bonus: 0.20,
            crit_chance_bonus: 0.10
          },
          excludes: []
        },

        swift_traveler: {
          key: :swift_traveler,
          name: "Swift Traveler",
          description: "+30% movement speed. +20% flee success chance.",
          category: :utility,
          level_required: 5,
          effects: {
            movement_speed_bonus: 0.30,
            flee_chance_bonus: 0.20
          },
          excludes: []
        },

        merchant: {
          key: :merchant,
          name: "Merchant",
          description: "+20% better prices when trading. +10% gold found.",
          category: :utility,
          level_required: 10,
          effects: {
            trade_bonus: 0.20,
            gold_find_bonus: 0.10
          },
          excludes: []
        }
      }.freeze

      # Category definitions
      CATEGORIES = {
        combat: {name: "Combat", description: "Offensive combat bonuses"},
        magic: {name: "Magic", description: "Spell and elemental bonuses"},
        defense: {name: "Defense", description: "Defensive and survival bonuses"},
        utility: {name: "Utility", description: "Experience, loot, and movement bonuses"}
      }.freeze

      class << self
        # Find a perk definition by key
        #
        # @param perk_key [Symbol, String] the perk identifier
        # @return [Hash, nil] perk definition or nil if not found
        def find(perk_key)
          PERKS[perk_key.to_sym]
        end

        # Get all registered perk keys
        #
        # @return [Array<Symbol>] list of all perk keys
        def all_keys
          PERKS.keys
        end

        # Get all perk definitions
        #
        # @return [Hash] all perk definitions
        def all
          PERKS
        end

        # Get perks by category
        #
        # @param category [Symbol] the category to filter by
        # @return [Array<Hash>] perks in that category
        def by_category(category)
          PERKS.values.select { |perk| perk[:category] == category.to_sym }
        end

        # Check if a perk key is valid
        #
        # @param perk_key [Symbol, String] the perk identifier
        # @return [Boolean] true if perk exists
        def valid?(perk_key)
          PERKS.key?(perk_key.to_sym)
        end

        # Get perks that would be excluded by selecting a specific perk
        #
        # @param perk_key [Symbol, String] the perk identifier
        # @return [Array<Symbol>] array of excluded perk keys
        def excluded_by(perk_key)
          perk = find(perk_key)
          return [] unless perk

          perk[:excludes] || []
        end

        # Check if two perks are mutually exclusive
        #
        # @param perk_a [Symbol, String] first perk
        # @param perk_b [Symbol, String] second perk
        # @return [Boolean] true if perks exclude each other
        def mutually_exclusive?(perk_a, perk_b)
          a = find(perk_a)
          b = find(perk_b)
          return false unless a && b

          a[:excludes]&.include?(perk_b.to_sym) || b[:excludes]&.include?(perk_a.to_sym)
        end

        # Get all perks available for a character (not already selected, not excluded)
        #
        # @param character [Character] the character to check
        # @return [Array<Hash>] available perk definitions
        def available_for(character)
          selected_keys = extract_selected_keys(character.perks)
          excluded = selected_keys.flat_map { |key| excluded_by(key) }.uniq

          PERKS.values.select do |perk|
            perk[:level_required] <= character.level &&
              !selected_keys.include?(perk[:key].to_s) &&
              !excluded.include?(perk[:key])
          end
        end

        # Check if a character can select a specific perk
        #
        # @param character [Character] the character to check
        # @param perk_key [Symbol, String] the perk to check
        # @return [Hash] { allowed: Boolean, reason: String }
        def can_select?(character, perk_key)
          perk = find(perk_key)
          return {allowed: false, reason: "Perk not found"} unless perk

          # Check level requirement
          if character.level < perk[:level_required]
            return {allowed: false, reason: "Requires level #{perk[:level_required]}"}
          end

          selected_keys = extract_selected_keys(character.perks)

          # Check if already selected
          if selected_keys.include?(perk_key.to_s)
            return {allowed: false, reason: "Perk already selected"}
          end

          # Check mutual exclusions
          excluded_by_selected = selected_keys.flat_map { |key| excluded_by(key) }.uniq

          if excluded_by_selected.include?(perk_key.to_sym)
            return {allowed: false, reason: "Excluded by another selected perk"}
          end

          # Check perk points
          if character.perk_points_available <= 0
            return {allowed: false, reason: "No perk points available"}
          end

          {allowed: true, reason: nil}
        end

        # Extract perk keys from various formats (Hash or Array)
        # Internal helper method
        def extract_selected_keys(perks)
          return [] if perks.nil?
          return perks if perks.is_a?(Array)
          return perks.keys if perks.is_a?(Hash)

          []
        end

        # Calculate perk points earned at a given level
        #
        # @param level [Integer] character level
        # @return [Integer] total perk points earned
        def perk_points_at_level(level)
          level / PERK_POINTS_PER_LEVEL_INTERVAL
        end

        # Get category definitions
        #
        # @return [Hash] category definitions
        def categories
          CATEGORIES
        end

        # Get perks grouped by category
        #
        # @return [Hash<Symbol, Array<Hash>>] category => [perks]
        def grouped_by_category
          PERKS.values.group_by { |p| p[:category] }
        end
      end
    end
  end
end
