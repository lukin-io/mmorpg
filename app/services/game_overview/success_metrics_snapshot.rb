# frozen_string_literal: true

require "set"

module GameOverview
  # SuccessMetricsSnapshot aggregates live retention/community/monetization KPIs.
  # It can return an attributes hash for presenters or persist data for trend charts.
  # Usage:
  #   snapshot = GameOverview::SuccessMetricsSnapshot.new.call
  #   GameOverviewSnapshot.create!(snapshot)
  class SuccessMetricsSnapshot
    RETENTION_WINDOWS = {
      daily: 1.day,
      weekly: 7.days
    }.freeze
    COMMUNITY_WINDOW = 7.days
    MONETIZATION_WINDOW = 30.days

    def initialize(now: Time.current)
      @now = now
    end

    def call
      {
        captured_at: now,
        daily_returning_players: returning_players(window: RETENTION_WINDOWS[:daily]),
        weekly_returning_players: returning_players(window: RETENTION_WINDOWS[:weekly]),
        chat_senders_7d: chat_senders(window: COMMUNITY_WINDOW),
        active_guilds_7d: active_guilds(window: COMMUNITY_WINDOW),
        active_clans_7d: active_clans(window: COMMUNITY_WINDOW),
        seasonal_events_active: EventInstance.active.count,
        premium_purchases_30d: premium_purchases(window: MONETIZATION_WINDOW),
        avg_tokens_per_paying_user: avg_tokens_per_paying_user(window: MONETIZATION_WINDOW),
        whale_share_percent: whale_share_percent(window: MONETIZATION_WINDOW)
      }
    end

    private

    attr_reader :now

    def returning_players(window:)
      since = now - window
      participants = Set.new

      quest_user_ids = Character.joins(:quest_assignments)
        .where(quest_assignments: {updated_at: since..now})
        .distinct
        .pluck(:user_id)

      crafting_user_ids = CraftingJob.where(updated_at: since..now).distinct.pluck(:user_id)
      chat_user_ids = ChatMessage.where(created_at: since..now).distinct.pluck(:sender_id)

      participants.merge(quest_user_ids.compact)
      participants.merge(crafting_user_ids.compact)
      participants.merge(chat_user_ids.compact)

      participants.size
    end

    def chat_senders(window:)
      since = now - window
      ChatMessage.where(created_at: since..now).distinct.count(:sender_id)
    end

    def active_guilds(window:)
      since = now - window
      Guild.joins(:guild_memberships)
        .where(guild_memberships: {status: GuildMembership.statuses[:active], updated_at: since..now})
        .distinct
        .count
    end

    def active_clans(window:)
      since = now - window
      Clan.joins(:clan_memberships)
        .where(clan_memberships: {updated_at: since..now})
        .distinct
        .count
    end

    def premium_purchases(window:)
      since = now - window
      Purchase.where(status: :succeeded, created_at: since..now).count
    end

    def avg_tokens_per_paying_user(window:)
      totals = premium_token_totals(window:)
      return 0 if totals.empty?

      (totals.values.sum.to_f / totals.size).round(2)
    end

    def whale_share_percent(window:)
      totals = premium_token_totals(window:)
      return 0 if totals.empty?

      sorted = totals.values.sort.reverse
      top_count = [(sorted.size * 0.05).ceil, 1].max
      top_sum = sorted.first(top_count).sum
      overall = sorted.sum

      ((top_sum.to_f / overall) * 100).round(2)
    end

    def premium_token_totals(window:)
      since = now - window
      PremiumTokenLedgerEntry.purchase_entry.where(created_at: since..now).group(:user_id).sum(:delta)
    end
  end
end
