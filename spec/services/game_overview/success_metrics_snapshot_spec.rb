# frozen_string_literal: true

require "rails_helper"

RSpec.describe GameOverview::SuccessMetricsSnapshot do
  include ActiveSupport::Testing::TimeHelpers

  describe "#call" do
    it "aggregates retention, community, and monetization KPIs" do
      freeze_time do
        user = create(:user)
        character = create(:character, user:)
        quest = create(:quest)
        create(:quest_assignment, quest:, character:, updated_at: 1.hour.ago)
        create(:crafting_job, user:, character:, updated_at: 30.minutes.ago)
        create(:chat_message, sender: user, created_at: 10.minutes.ago)

        guild = create(:guild, leader: user)
        create(:guild_membership, guild:, user:, updated_at: 2.hours.ago)

        clan = create(:clan, leader: user)
        create(:clan_membership, clan:, user:, updated_at: 2.hours.ago)

        event = create(:game_event)
        EventInstance.create!(
          game_event: event,
          status: :active,
          starts_at: Time.current,
          ends_at: 1.day.from_now,
          metadata: {}
        )

        ledger_user = create(:user)
        create(:premium_token_ledger_entry, user: ledger_user, delta: 200, balance_after: 200, created_at: 1.day.ago)
        create(:premium_token_ledger_entry, user:, delta: 50, balance_after: 50, created_at: 1.day.ago)

        create(:purchase, user:, status: :succeeded, metadata: {"token_amount" => 100}, created_at: 2.days.ago)

        snapshot = described_class.new.call

        expect(snapshot[:daily_returning_players]).to eq(1)
        expect(snapshot[:weekly_returning_players]).to eq(1)
        expect(snapshot[:chat_senders_7d]).to eq(1)
        expect(snapshot[:active_guilds_7d]).to eq(1)
        expect(snapshot[:active_clans_7d]).to eq(1)
        expect(snapshot[:seasonal_events_active]).to eq(1)
        expect(snapshot[:premium_purchases_30d]).to eq(1)
        expect(snapshot[:avg_tokens_per_paying_user]).to be > 0
        expect(snapshot[:whale_share_percent]).to be_between(0, 100)
      end
    end
  end
end
