# frozen_string_literal: true

module GameOverview
  # OverviewPresenter orchestrates copy from SectionCatalog plus live metrics so
  # the `/game_overview` page can remain declarative in its views.
  class OverviewPresenter
    MetricCard = Struct.new(:key, :title, :description, :value, :delta, :format, keyword_init: true)

    def initialize(section_catalog: SectionCatalog.new, metrics_service: SuccessMetricsSnapshot.new, cache: Rails.cache)
      @section_catalog = section_catalog
      @metrics_service = metrics_service
      @cache = cache
    end

    def hero
      section_catalog.hero
    end

    def sections
      section_catalog.sections
    end

    def section(key)
      section_catalog.section(key).content
    end

    def platform_stack_cards
      templates = section(:platform_technology).fetch(:technology_stack, [])
      templates.map do |card|
        template = card[:value_template]
        value = template ? format(template, stack_context) : card[:value]
        card.merge(value:)
      end
    end

    def metrics_snapshot
      @metrics_snapshot ||= GameOverviewSnapshot.latest || build_ephemeral_snapshot
    end

    def previous_snapshot
      @previous_snapshot ||= GameOverviewSnapshot.previous
    end

    def metrics_cards
      metrics_config = section_catalog.success_metrics.content.fetch(:metrics, [])
      metrics_config.map do |config|
        key = config.fetch(:key).to_sym
        value = metrics_snapshot.value_for(key)
        delta = delta_for(key, value)
        MetricCard.new(
          key: key,
          title: config.fetch(:title),
          description: config.fetch(:description),
          value: value,
          delta: delta,
          format: config.fetch(:format, :count)
        )
      end
    end

    private

    attr_reader :section_catalog, :metrics_service, :cache

    def build_ephemeral_snapshot
      attrs = cache.fetch("game_overview/metrics_ephemeral", expires_in: 5.minutes) do
        metrics_service.call
      end

      GameOverviewSnapshot.new(attrs)
    end

    def delta_for(key, current_value)
      return nil unless previous_snapshot

      current_value - previous_snapshot.value_for(key)
    end

    def stack_context
      @stack_context ||= {
        rails_version: Rails.version,
        ruby_version: RUBY_VERSION,
        hotwire_stack: "Turbo • Stimulus • ViewComponent",
        persistence_layer: "PostgreSQL • Redis (cache, Action Cable, Sidekiq)",
        job_stack: "Sidekiq queues: default/combat/chat/payments/moderation/live_ops/low"
      }
    end
  end
end
