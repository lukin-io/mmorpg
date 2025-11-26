# frozen_string_literal: true

module Api
  module V1
    class FanToolsController < BaseController
      def index
        render json: {
          achievements: achievements_payload,
          housing_showcase: housing_payload,
          generated_at: Time.current
        }
      end

      private

      def achievements_payload
        Achievement.ordered_for_showcase.limit(20).map do |achievement|
          achievement.slice(:key, :name, :category, :points, :share_payload)
        end
      end

      def housing_payload
        HousingPlot.showcased.limit(10).map do |plot|
          plot.showcase_payload.merge(owner: plot.user.profile_name)
        end
      end
    end
  end
end
