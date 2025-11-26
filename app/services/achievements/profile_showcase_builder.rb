# frozen_string_literal: true

module Achievements
  # ProfileShowcaseBuilder aggregates top achievements/titles for display on profiles,
  # housing plaques, and Discord/Forum integrations.
  #
  # Usage:
  #   Achievements::ProfileShowcaseBuilder.new(user: user).call
  #
  # Returns:
  #   Hash with :categories, :titles, and :share_payload keys.
  class ProfileShowcaseBuilder
    MAX_PER_CATEGORY = 3

    def initialize(user:)
      @user = user
    end

    def call
      {
        categories: grouped_achievements,
        titles: title_payload,
        share_payload: share_payload
      }
    end

    private

    attr_reader :user

    def grouped_achievements
      grants = user.achievement_grants.includes(:achievement)
      grants.group_by { |grant| grant.achievement.category }.transform_values do |group|
        group.sort_by { |grant| -grant.achievement.points }.first(MAX_PER_CATEGORY).map do |grant|
          {
            name: grant.achievement.name,
            points: grant.achievement.points,
            granted_at: grant.granted_at
          }
        end
      end
    end

    def title_payload
      user.title_grants.includes(:title).map do |grant|
        {
          name: grant.title.name,
          equipped: grant.equipped,
          perks: grant.title.perks,
          priority_party_finder: grant.title.priority_party_finder
        }
      end
    end

    def share_payload
      {
        profile_name: user.profile_name,
        top_achievement: user.achievement_grants
          .includes(:achievement)
          .max_by { |grant| grant.achievement.points }
          &.achievement
          &.share_payload
      }
    end
  end
end
