# frozen_string_literal: true

require "yaml"
require "erb"

module GameOverview
  # SectionCatalog loads the static copy for the overview page directly from
  # `config/game_overview.yml` so the implemented UI stays in sync with the spec.
  # Usage:
  #   catalog = GameOverview::SectionCatalog.new
  #   catalog.section(:vision_objectives)
  class SectionCatalog
    Section = Struct.new(:key, :content, keyword_init: true)

    CONFIG_PATH = Rails.root.join("config/game_overview.yml")

    def initialize(config_path: CONFIG_PATH, env: Rails.env)
      @config_path = config_path
      @env = env
    end

    def hero
      config.fetch("hero").deep_symbolize_keys
    end

    def sections
      @sections ||= sections_hash.map do |key, value|
        Section.new(key: key.to_sym, content: value.deep_symbolize_keys)
      end
    end

    def section(key)
      sections_index.fetch(key.to_sym)
    end

    def success_metrics
      section(:success_metrics)
    end

    private

    attr_reader :config_path, :env

    def config
      @config ||= load_config
    end

    def sections_hash
      config.fetch("sections")
    end

    def sections_index
      @sections_index ||= sections.index_by(&:key)
    end

    def load_config
      raw = ERB.new(File.read(config_path)).result
      data = YAML.safe_load(raw, aliases: true)
      (data[env] || data["default"]).with_indifferent_access
    end
  end
end
