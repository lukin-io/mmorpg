# frozen_string_literal: true

module Game
  module Professions
    # Loads Ashen workshop profession/recipe config.
    class Catalog
      CONFIG_PATH = Rails.root.join("config/gameplay/ashen_professions.yml")

      class InvalidConfigurationError < StandardError; end

      class << self
        def reload!
          @config = nil
          config
        end

        def config
          @config ||= load_config!
        end

        def professions
          config.fetch("professions")
        end

        def recipes
          config.fetch("recipes")
        end

        def recipe(key)
          recipes[key.to_s]
        end

        def recipes_for_building(building_key)
          recipes.select do |_key, recipe|
            profession = professions.fetch(recipe.fetch("profession"))
            profession.fetch("building_key") == building_key.to_s
          end
        end

        private

        def load_config!
          raw = YAML.load_file(CONFIG_PATH)
          raise InvalidConfigurationError, "ashen_professions.yml must be a Hash" unless raw.is_a?(Hash)

          professions = raw.fetch("professions")
          recipes = raw.fetch("recipes")
          raise InvalidConfigurationError, "professions missing" unless professions.is_a?(Hash)
          raise InvalidConfigurationError, "recipes missing" unless recipes.is_a?(Hash)

          recipes = recipes.merge(PotionCatalog.recipe_entries)

          recipes.each do |key, recipe|
            raise InvalidConfigurationError, "#{key} inputs missing" unless recipe["inputs"].is_a?(Hash)
            raise InvalidConfigurationError, "#{key} output missing" unless recipe.dig("output", "item_key").present?
            profession_key = recipe["profession"].to_s
            raise InvalidConfigurationError, "#{key} unknown profession" unless professions.key?(profession_key)
          end

          {
            "professions" => professions.transform_keys(&:to_s),
            "recipes" => recipes.transform_keys(&:to_s)
          }
        end
      end
    end
  end
end
