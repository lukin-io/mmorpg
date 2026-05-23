# frozen_string_literal: true

module Game
  module Skills
    # Source-backed registry for Neverlands numeric `Umeniya` skills.
    #
    # The ids and tier rates come from the captured Neverlands skills page and
    # `addskill_v02.js`. This registry intentionally does not define gameplay
    # effect formulas or prerequisite rules; those must be captured separately
    # before they become implementation.
    class PassiveSkillRegistry
      MAX_LEVEL = 100

      POOL_COMBAT = :combat
      POOL_PEACE = :peace

      CATEGORIES = {
        combat: {name: "Боевые умения", pool: POOL_COMBAT},
        resistance: {name: "Сопротивления", pool: POOL_COMBAT},
        magic: {name: "Магия", pool: POOL_COMBAT},
        peace_world: {name: "Мирные умения", pool: POOL_PEACE}
      }.freeze

      SKILL_ROWS = [
        [0, :unarmed_combat, "Рукопашный бой", :combat, "10:8:6:4"],
        [1, :sword_mastery, "Владение мечами", :combat, "8:6:4:2"],
        [2, :axe_mastery, "Владение топорами", :combat, "8:6:4:2"],
        [3, :bludgeoning_mastery, "Владение дробящим оружием", :combat, "8:6:4:2"],
        [4, :knife_mastery, "Владение ножами", :combat, "8:6:4:2"],
        [5, :throwing_mastery, "Владение метательным оружием", :combat, "8:6:4:2"],
        [6, :polearm_mastery, "Владение алебардами и копьями", :combat, "8:6:4:2"],
        [7, :staff_mastery, "Владение посохами", :combat, "8:6:4:2"],
        [8, :exotic_weapon_mastery, "Владение экзотическим оружием", :combat, "6:4:4:2"],
        [9, :two_handed_mastery, "Владение двуручным оружием", :combat, "10:8:6:4"],
        [10, :dual_wielding, "Владение двумя руками", :combat, "4:4:2:2"],
        [11, :extra_action_points, "Доп. очки действия", :combat, "2:2:2:2"],
        [16, :fire_magic_resistance, "Сопротивление магии огня", :resistance, "6:4:2:2"],
        [17, :water_magic_resistance, "Сопротивление магии воды", :resistance, "6:4:2:2"],
        [18, :air_magic_resistance, "Сопротивление магии воздуха", :resistance, "6:4:2:2"],
        [19, :earth_magic_resistance, "Сопротивление магии земли", :resistance, "6:4:2:2"],
        [20, :physical_damage_resistance, "Сопротивление физ. поврежд.", :resistance, "6:4:2:2"],
        [12, :fire_magic, "Магия огня", :magic, "8:6:4:2"],
        [13, :water_magic, "Магия воды", :magic, "8:6:4:2"],
        [14, :air_magic, "Магия воздуха", :magic, "8:6:4:2"],
        [15, :earth_magic, "Магия земли", :magic, "8:6:4:2"],
        [22, :caution, "Осторожность", :peace_world, "2:2:2:2"],
        [23, :stealth, "Скрытность", :peace_world, "2:2:2:2"],
        [24, :observation, "Наблюдательность", :peace_world, "2:2:2:2"],
        [26, :wanderer, "Странник", :peace_world, "2:2:2:2"],
        [27, :linguistics, "Языковедение", :peace_world, "2:2:2:2"],
        [30, :self_healing, "Самолечение", :peace_world, "2:2:2:2"],
        [33, :fast_mana_regeneration, "Быстрое восстановление маны", :peace_world, "2:2:2:2"],
        [34, :leadership, "Лидерство", :peace_world, "6:4:3:2"]
      ].freeze

      SKILLS = SKILL_ROWS.each_with_object({}) do |(source_id, key, name, category, progression_rate), memo|
        memo[key] = {
          key:,
          source_id:,
          name:,
          description: "Neverlands numeric skill ##{source_id}.",
          max_level: MAX_LEVEL,
          category:,
          pool: CATEGORIES.fetch(category).fetch(:pool),
          progression_rate:
        }
      end.freeze

      SOURCE_ID_INDEX = SKILLS.transform_values { |definition| definition[:source_id] }.invert.freeze

      class << self
        def find(skill_key)
          return nil if skill_key.blank?

          SKILLS[skill_key.to_sym]
        end

        def find_by_source_id(source_id)
          key = SOURCE_ID_INDEX[source_id.to_i]
          key ? find(key) : nil
        end

        def all_keys
          SKILLS.keys
        end

        def all
          SKILLS
        end

        def by_category(category)
          SKILLS.values.select { |skill| skill[:category] == category.to_sym }
        end

        def by_pool(pool)
          SKILLS.values.select { |skill| skill[:pool] == pool.to_sym }
        end

        def valid?(skill_key)
          find(skill_key).present?
        end

        def calculate_effect(_skill_key, _level)
          0.0
        end

        def max_level(skill_key)
          find(skill_key)&.dig(:max_level)
        end

        def progression_rate(skill_key)
          find(skill_key)&.dig(:progression_rate)
        end

        def pool_for(skill_key)
          find(skill_key)&.dig(:pool)
        end

        def categories
          CATEGORIES
        end

        def grouped_by_category
          SKILLS.values.group_by { |skill| skill[:category] }
            .transform_values { |skills| skills.map { |skill| skill[:key] } }
        end

        def prerequisites(_skill_key)
          nil
        end

        def prerequisites_met?(_skill_key, _character)
          {met: true, missing: []}
        end

        def can_spend?(skill_key, character)
          skill = find(skill_key)
          return {allowed: false, reason: "Skill not found"} unless skill

          pool = skill[:pool]
          available = character.available_skill_points_for_pool(pool)
          return {allowed: false, reason: "No #{pool} skill points available"} if available <= 0

          current_level = character.passive_skill_level(skill_key)
          max = skill[:max_level] || MAX_LEVEL
          return {allowed: false, reason: "Skill is at maximum level"} if current_level >= max

          {allowed: true, reason: nil}
        end

        def available_for(character)
          SKILLS.keys.select { |skill_key| can_spend?(skill_key, character)[:allowed] }
        end

        def locked_skills_for(_character)
          []
        end
      end
    end
  end
end
