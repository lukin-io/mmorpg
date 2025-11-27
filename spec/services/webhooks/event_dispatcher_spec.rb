# frozen_string_literal: true

require "rails_helper"

RSpec.describe Webhooks::EventDispatcher do
  describe ".dispatch" do
    let(:user) { create(:user) }
    let(:integration_token) { create(:integration_token, user: user) }
    let!(:webhook_endpoint) do
      create(:webhook_endpoint,
        integration_token: integration_token,
        enabled: true,
        event_types: ["achievement.unlocked", "player.level_up"])
    end

    context "with valid event type" do
      it "creates a webhook event" do
        expect {
          described_class.dispatch(
            event_type: "achievement.unlocked",
            payload: {user_id: user.id, achievement_key: "first_kill"}
          )
        }.to change(WebhookEvent, :count).by(1)
      end

      it "queues delivery job" do
        expect {
          described_class.dispatch(
            event_type: "achievement.unlocked",
            payload: {user_id: user.id}
          )
        }.to have_enqueued_job(Webhooks::DeliverJob)
      end

      it "returns the created event" do
        event = described_class.dispatch(
          event_type: "achievement.unlocked",
          payload: {user_id: user.id}
        )

        expect(event).to be_a(WebhookEvent)
        expect(event.event_type).to eq("achievement.unlocked")
      end
    end

    context "with invalid event type" do
      it "returns nil for unrecognized event types" do
        result = described_class.dispatch(
          event_type: "invalid.event",
          payload: {}
        )

        expect(result).to be_nil
      end
    end

    context "with no subscribed endpoints" do
      before { webhook_endpoint.update!(event_types: []) }

      it "returns nil when no endpoints subscribe to the event" do
        result = described_class.dispatch(
          event_type: "achievement.unlocked",
          payload: {}
        )

        expect(result).to be_nil
      end
    end

    context "with disabled endpoint" do
      before { webhook_endpoint.update!(enabled: false) }

      it "does not deliver to disabled endpoints" do
        expect {
          described_class.dispatch(
            event_type: "achievement.unlocked",
            payload: {}
          )
        }.not_to have_enqueued_job(Webhooks::DeliverJob)
      end
    end
  end

  describe "#deliver!" do
    let(:user) { create(:user) }
    let(:integration_token) { create(:integration_token, user: user) }
    let(:webhook_endpoint) do
      create(:webhook_endpoint,
        integration_token: integration_token,
        enabled: true,
        target_url: "https://example.com/webhook",
        secret: "test_secret")
    end
    let(:webhook_event) do
      create(:webhook_event,
        webhook_endpoint: webhook_endpoint,
        event_type: "test.event",
        payload: {test: true}.to_json,
        status: :pending)
    end

    subject(:dispatcher) do
      described_class.new(event: webhook_event, endpoint: webhook_endpoint)
    end

    context "with successful delivery" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")
      end

      it "marks event as delivered" do
        dispatcher.deliver!

        expect(webhook_event.reload.status).to eq("delivered")
      end

      it "sets delivered_at timestamp" do
        dispatcher.deliver!

        expect(webhook_event.reload.delivered_at).to be_present
      end

      it "returns true" do
        expect(dispatcher.deliver!).to be true
      end
    end

    context "with failed delivery" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 500, body: "Server Error")
      end

      it "marks event as failed" do
        dispatcher.deliver!

        expect(webhook_event.reload.status).to eq("failed")
      end

      it "increments attempts" do
        expect { dispatcher.deliver! }.to change { webhook_event.reload.attempts }.by(1)
      end

      it "schedules retry" do
        expect { dispatcher.deliver! }.to have_enqueued_job(Webhooks::DeliverJob)
      end

      it "returns false" do
        expect(dispatcher.deliver!).to be false
      end
    end

    context "with disabled endpoint" do
      before { webhook_endpoint.update!(enabled: false) }

      it "returns false" do
        expect(dispatcher.deliver!).to be false
      end
    end
  end
end
