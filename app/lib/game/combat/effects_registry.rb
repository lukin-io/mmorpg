# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Registry of all combat effects with their definitions.
    #
    # Usage:
    #   effect_def = Game::Combat::EffectsRegistry.find(:poison)
    #   effect = Game::Combat::EffectsRegistry.create(:poison)
    #
    class EffectsRegistry
      # Combat effect definitions
      EFFECTS = {
        # Damage Over Time (DOT) effects
        poison: {
          type: :dot,
          name: "Poison",
          duration: 3,
          damage_per_turn: 5,
          element: "nature",
          description: "Deals nature damage each turn"
        },
        burn: {
          type: :dot,
          name: "Burning",
          duration: 2,
          damage_per_turn: 8,
          element: "fire",
          description: "Deals fire damage each turn"
        },
        bleed: {
          type: :dot,
          name: "Bleeding",
          duration: 4,
          damage_per_turn: 3,
          element: "normal",
          description: "Deals physical damage each turn, stacks"
        },
        frostbite: {
          type: :dot,
          name: "Frostbite",
          duration: 3,
          damage_per_turn: 4,
          stat_changes: {agility: -5},
          element: "water",
          description: "Deals cold damage and reduces agility"
        },
        shock: {
          type: :dot,
          name: "Shocked",
          duration: 2,
          damage_per_turn: 6,
          stat_changes: {accuracy: -10},
          element: "air",
          description: "Deals lightning damage and reduces accuracy"
        },

        # Heal Over Time (HOT) effects
        regeneration: {
          type: :hot,
          name: "Regeneration",
          duration: 5,
          heal_per_turn: 10,
          description: "Restores HP each turn"
        },
        blessing: {
          type: :hot,
          name: "Angel's Blessing",
          duration: 3,
          heal_per_turn: 15,
          stat_changes: {luck: 5},
          element: "holy",
          description: "Restores HP and increases luck"
        },

        # Shield/Barrier effects
        magic_shield: {
          type: :shield,
          name: "Magic Shield",
          duration: 2,
          damage_reduction: 0.3,
          element: "arcane",
          description: "Reduces incoming damage by 30%"
        },
        rainbow_barrier: {
          type: :barrier,
          name: "Rainbow Barrier",
          duration: 2,
          damage_reduction: 0.5,
          element: "arcane",
          description: "Reduces incoming damage by 50%"
        },
        crystal_sphere: {
          type: :immunity,
          name: "Crystal Sphere",
          duration: 1,
          damage_reduction: 1.0,
          element: "earth",
          description: "Completely negates one attack"
        },
        stone_skin: {
          type: :shield,
          name: "Stone Skin",
          duration: 3,
          damage_reduction: 0.25,
          stat_changes: {defense: 10},
          element: "earth",
          description: "Reduces damage and increases defense"
        },

        # Stat Buff effects
        berserker: {
          type: :buff,
          name: "Berserker",
          duration: 3,
          stat_changes: {strength: 15, defense: -10},
          description: "Increases strength but reduces defense"
        },
        strength_potion: {
          type: :buff,
          name: "Strength Potion",
          duration: 5,
          stat_changes: {strength: 10},
          description: "Increases strength"
        },
        agility_potion: {
          type: :buff,
          name: "Agility Potion",
          duration: 5,
          stat_changes: {agility: 10},
          description: "Increases agility"
        },
        precision_potion: {
          type: :buff,
          name: "Precision Potion",
          duration: 5,
          stat_changes: {accuracy: 15},
          description: "Increases accuracy"
        },
        luck_potion: {
          type: :buff,
          name: "Luck Potion",
          duration: 5,
          stat_changes: {luck: 10},
          description: "Increases luck"
        },
        endurance_potion: {
          type: :buff,
          name: "Endurance Potion",
          duration: 5,
          stat_changes: {endurance: 10},
          description: "Increases endurance"
        },
        intelligence_potion: {
          type: :buff,
          name: "Enlightenment Potion",
          duration: 5,
          stat_changes: {intelligence: 10},
          description: "Increases intelligence"
        },
        immunity_potion: {
          type: :buff,
          name: "Immunity Potion",
          duration: 3,
          stat_changes: {},
          description: "Prevents negative status effects"
        },

        # Stat Debuff effects
        weakness: {
          type: :debuff,
          name: "Weakness",
          duration: 3,
          stat_changes: {strength: -10},
          description: "Reduces strength"
        },
        slow: {
          type: :slow,
          name: "Slowed",
          duration: 2,
          stat_changes: {agility: -15},
          description: "Reduces agility significantly"
        },
        blind: {
          type: :debuff,
          name: "Blinded",
          duration: 2,
          stat_changes: {accuracy: -20},
          description: "Greatly reduces accuracy"
        },
        curse: {
          type: :debuff,
          name: "Dark Curse",
          duration: 4,
          stat_changes: {luck: -15, strength: -5},
          description: "Reduces luck and strength"
        },
        fear: {
          type: :debuff,
          name: "Fear",
          duration: 2,
          stat_changes: {strength: -10, defense: -5},
          description: "Reduces combat effectiveness"
        },

        # Control effects
        stun: {
          type: :stun,
          name: "Stunned",
          duration: 1,
          description: "Cannot act for one turn"
        },
        freeze: {
          type: :stun,
          name: "Frozen",
          duration: 1,
          stat_changes: {agility: -20},
          element: "water",
          description: "Cannot act and reduced agility"
        },

        # Elemental resistance buffs
        fire_resistance: {
          type: :buff,
          name: "Fire Resistance",
          duration: 5,
          stat_changes: {},
          element: "fire",
          description: "Reduces fire damage taken by 40%"
        },
        cold_resistance: {
          type: :buff,
          name: "Cold Resistance",
          duration: 5,
          stat_changes: {},
          element: "water",
          description: "Reduces cold damage taken by 40%"
        },
        lightning_resistance: {
          type: :buff,
          name: "Lightning Resistance",
          duration: 5,
          stat_changes: {},
          element: "air",
          description: "Reduces lightning damage taken by 40%"
        },

        # Special combat effects
        combat_trauma: {
          type: :debuff,
          name: "Combat Trauma",
          duration: 10,
          stat_changes: {strength: -5, agility: -5},
          description: "Post-combat weakness"
        },
        battle_glory: {
          type: :buff,
          name: "Battle Glory",
          duration: 3,
          stat_changes: {strength: 5, luck: 5},
          description: "Victory bonus"
        },
        bodyguard: {
          type: :shield,
          name: "Bodyguard",
          duration: 3,
          damage_reduction: 0.2,
          description: "Ally absorbs some damage"
        }
      }.freeze

      class << self
        # Find an effect definition by key
        #
        # @param key [Symbol, String] effect key
        # @return [Hash, nil] effect definition
        def find(key)
          EFFECTS[key.to_sym]
        end

        # Create an Effect instance from registry
        #
        # @param key [Symbol, String] effect key
        # @param overrides [Hash] override default values
        # @return [Effect, nil]
        def create(key, **overrides)
          definition = find(key)
          return nil unless definition

          params = definition.merge(overrides)
          Effect.new(**params.except(:description))
        end

        # Get all effect keys
        #
        # @return [Array<Symbol>]
        def keys
          EFFECTS.keys
        end

        # Get all effects of a specific type
        #
        # @param type [Symbol] effect type (:dot, :buff, :debuff, etc.)
        # @return [Hash] matching effects
        def by_type(type)
          EFFECTS.select { |_, v| v[:type] == type.to_sym }
        end

        # Get all beneficial effects
        #
        # @return [Hash]
        def beneficial
          EFFECTS.select { |_, v| %i[buff hot shield barrier immunity].include?(v[:type]) }
        end

        # Get all harmful effects
        #
        # @return [Hash]
        def harmful
          EFFECTS.select { |_, v| %i[debuff dot stun slow].include?(v[:type]) }
        end

        # Get effects by element
        #
        # @param element [String] element name
        # @return [Hash]
        def by_element(element)
          EFFECTS.select { |_, v| v[:element] == element }
        end
      end
    end
  end
end
