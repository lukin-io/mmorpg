# frozen_string_literal: true

module Game
  module Quests
    # Loads sandbox Ashen quest definitions from YAML.
    class Catalog
      CONFIG_PATH = Rails.root.join("config/gameplay/ashen_quests.yml")

      class << self
        def all
          @all ||= load_quests
        end

        def reload!
          @all = nil
          all
        end

        def find(key)
          all[key.to_s]
        end

        def ordered
          all.values.sort_by { |quest| [quest.fetch("sort", 100), quest.fetch("key")] }
        end

        private

        def load_quests
          raw = YAML.safe_load_file(CONFIG_PATH, aliases: false) || {}
          entries = raw.fetch("quests")
          entries.each_with_object({}) do |(key, attrs), memo|
            memo[key.to_s] = attrs.to_h.merge("key" => key.to_s).deep_stringify_keys
          end
        end
      end
    end
  end
end
