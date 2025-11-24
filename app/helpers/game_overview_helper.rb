# frozen_string_literal: true

# GameOverviewHelper centralizes formatting helpers for metric cards.
module GameOverviewHelper
  def formatted_metric_value(metric)
    case metric.format.to_sym
    when :percent
      number_with_precision(metric.value.to_f, precision: 2).concat("%")
    when :decimal
      number_with_precision(metric.value.to_f, precision: 2)
    else
      number_with_delimiter(metric.value.to_i)
    end
  end

  def metric_delta_badge(delta, format: :count)
    return content_tag(:span, "—", class: "metric-delta neutral") if delta.nil? || delta.zero?

    direction = delta.positive? ? "positive" : "negative"
    value = case format
    when :percent
      "#{delta.positive? ? "+" : ""}#{number_with_precision(delta.to_f, precision: 2)}%"
    when :decimal
      "#{delta.positive? ? "+" : ""}#{number_with_precision(delta.to_f, precision: 2)}"
    else
      "#{delta.positive? ? "+" : ""}#{number_with_delimiter(delta.to_i)}"
    end

    content_tag(:span, value, class: "metric-delta #{direction}")
  end
end
