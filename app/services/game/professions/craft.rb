# frozen_string_literal: true

module Game
  module Professions
    # Authoritative Ashen workshop craft: success roll (dexterity), then consume
    # inputs, grant output, and gated profession skill gain under the character lock.
    # Soft-launch: a failed roll leaves materials intact and does not bump skill.
    class Craft
      Result = Struct.new(:success, :message, :recipe_key, :skill, keyword_init: true)
      SKILLS_KEY = "profession_skills"

      def initialize(character:, recipe_key:, rng: Random.new)
        @character = character
        @recipe_key = recipe_key.to_s
        @rng = rng
      end

      def call
        recipe = Catalog.recipe(recipe_key)
        return failure(I18n.t("game.professions.recipe_missing")) unless recipe
        if blood_iii_recipe?(recipe) && !Game::Clans::Laboratory.unlocked?(character)
          return failure(I18n.t("game.professions.laboratory_required"))
        end

        profession = Catalog.professions.fetch(recipe.fetch("profession"))
        skill_key = profession.fetch("skill_key")

        character.with_lock do
          character.reload
          inventory = character.inventory || character.create_inventory!
          skill = profession_skill(skill_key)
          difficulty = recipe_difficulty(recipe)
          if skill < difficulty
            return failure(
              I18n.t(
                "game.professions.need_skill_named",
                profession: profession_title(profession),
                amount: difficulty,
                current: skill
              )
            )
          end

          ensure_output_templates!(recipe)
          unless inputs_available?(inventory, recipe.fetch("inputs"))
            return failure(I18n.t("game.inventory.craft_missing_materials"))
          end

          unless craft_succeeds?(skill:, difficulty:)
            return failure(I18n.t("game.professions.craft_failed", name: recipe_title(recipe)))
          end

          manager = Game::Inventory::Manager.new(inventory:)
          recipe.fetch("inputs").each do |item_key, qty|
            template = ItemTemplate.find_by!(key: item_key.to_s)
            manager.remove_item!(item_template: template, quantity: qty.to_i)
          end

          output = recipe.fetch("output")
          out_template = ItemTemplate.find_by!(key: output.fetch("item_key").to_s)
          manager.add_item!(item_template: out_template, quantity: output.fetch("quantity", 1).to_i)

          gain = recipe.fetch("skill_gain", 1).to_i + craft_speed_skill_bonus
          new_skill = if skill_gain_succeeds?(skill:, difficulty:)
            bump_skill!(skill_key, gain)
          else
            skill
          end
          Game::Activity::Tracker.new(character:).record!(kind: "craft_item", amount: 1)
          Result.new(
            success: true,
            recipe_key:,
            skill: new_skill,
            message: I18n.t(
              "game.professions.crafted",
              name: recipe_title(recipe),
              profession: profession_title(profession),
              skill: new_skill
            )
          )
        end
      rescue StandardError => error
        raise unless error.class.name.end_with?("InventoryUnderflowError", "CapacityExceededError")

        if error.class.name.end_with?("CapacityExceededError")
          failure(I18n.t("game.inventory.craft_inventory_full"))
        else
          failure(I18n.t("game.inventory.craft_missing_materials"))
        end
      end

      private

      def craft_speed_skill_bonus
        # Laboratory craft_speed_percent: +1 skill tick per 50% (Ashen soft-release sink value).
        character.fortress_buffs.craft_speed_percent / 50
      end

      attr_reader :character, :recipe_key, :rng

      def recipe_difficulty(recipe)
        (recipe["difficulty"] || recipe["min_skill"] || 0).to_i
      end

      # success% = max(50 + (skill - difficulty) * 3 + dexterity * 0.2, 5).clamp(5, 95)
      def craft_succeeds?(skill:, difficulty:)
        base = 50 + ((skill - difficulty) * 3)
        dexterity = character.stats.get(:dexterity).to_i
        final = [base + (dexterity * 0.2), 5].max.clamp(5, 95)
        rng.rand < (final / 100.0)
      end

      # Within 10 skill of difficulty: always gain. Beyond that, chance falls to a 5% floor.
      def skill_gain_succeeds?(skill:, difficulty:)
        gap = skill - difficulty
        return true if gap < 10

        gain_chance = (100 - ((gap - 10) * 10)).clamp(5, 100)
        rng.rand < (gain_chance / 100.0)
      end

      def profession_skill(skill_key)
        character.metadata.to_h.dig(SKILLS_KEY, skill_key.to_s).to_i
      end

      def blood_iii_recipe?(recipe)
        potion = PotionCatalog.fetch(recipe.dig("output", "item_key"))
        potion && potion.fetch(:blood).to_i == 3
      end

      def bump_skill!(skill_key, gain)
        metadata = character.metadata.to_h
        skills = metadata[SKILLS_KEY].is_a?(Hash) ? metadata[SKILLS_KEY].dup : {}
        next_value = skills[skill_key.to_s].to_i + gain
        skills[skill_key.to_s] = next_value
        character.update!(metadata: metadata.merge(SKILLS_KEY => skills))
        next_value
      end

      def inputs_available?(inventory, inputs)
        inputs.all? do |item_key, qty|
          template = ItemTemplate.find_by(key: item_key.to_s)
          next false unless template

          inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity) >= qty.to_i
        end
      end

      def ensure_output_templates!(recipe)
        Templates.ensure_craft_items!
        recipe.fetch("inputs").each_key { |key| ItemTemplate.find_by!(key: key.to_s) }
        ItemTemplate.find_by!(key: recipe.dig("output", "item_key").to_s)
      end

      def recipe_title(recipe)
        locale_key = I18n.locale.to_s.start_with?("ru") ? "title_ru" : "title_en"
        recipe[locale_key].presence || recipe["title_ru"] || recipe_key
      end

      def profession_title(profession)
        locale_key = I18n.locale.to_s.start_with?("ru") ? "title_ru" : "title_en"
        profession[locale_key].presence || profession["title_ru"]
      end

      def failure(message)
        Result.new(success: false, message:, recipe_key:)
      end
    end
  end
end
