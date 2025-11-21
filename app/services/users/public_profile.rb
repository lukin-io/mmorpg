# frozen_string_literal: true

module Users
  class PublicProfile
    def initialize(user:)
      @user = user
    end

    def as_json(*)
      {
        id: user.id,
        profile_name: user.profile_name,
        reputation: user.reputation_score,
        achievements: achievements_payload,
        guild: guild_payload,
        clan: clan_payload,
        housing: housing_payload
      }
    end

    private

    attr_reader :user

    def achievements_payload
      user.achievement_grants.includes(:achievement).map do |grant|
        {
          name: grant.achievement.name,
          points: grant.achievement.points,
          granted_at: grant.granted_at
        }
      end
    end

    def guild_payload
      guild = user.primary_guild
      return if guild.nil?

      {
        name: guild.name,
        level: guild.level,
        slug: guild.slug
      }
    end

    def clan_payload
      clan = user.primary_clan
      return if clan.nil?

      {
        name: clan.name,
        slug: clan.slug,
        prestige: clan.prestige
      }
    end

    def housing_payload
      user.housing_plots.limit(3).map do |plot|
        {
          location_key: plot.location_key,
          plot_type: plot.plot_type,
          storage_slots: plot.storage_slots
        }
      end
    end
  end
end
