# frozen_string_literal: true

# EconomyAnalyticsJob snapshots auction/trade metrics and runs fraud detection.
class EconomyAnalyticsJob < ApplicationJob
  queue_as :default

  def perform
    Economy::AnalyticsReporter.new.call
    Economy::FraudDetector.new.call
  end
end
