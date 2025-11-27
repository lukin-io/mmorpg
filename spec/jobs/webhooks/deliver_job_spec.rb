# frozen_string_literal: true

require "rails_helper"

RSpec.describe Webhooks::DeliverJob, type: :job do
  let(:user) { create(:user) }
  let(:integration_token) { create(:integration_token, created_by: user) }
  let(:webhook_endpoint) do
    create(:webhook_endpoint,
      integration_token: integration_token,
      target_url: "https://example.com/webhook")
  end
  let(:webhook_event) do
    create(:webhook_event,
      webhook_endpoint: webhook_endpoint,
      status: :pending)
  end

  describe "#perform" do
    context "with successful delivery" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: "OK")
      end

      it "delivers the webhook" do
        described_class.perform_now(webhook_event.id, webhook_endpoint.id)

        expect(webhook_event.reload.status).to eq("delivered")
      end
    end

    context "with failed delivery" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 500, body: "Error")
      end

      it "marks as failed and schedules retry" do
        expect {
          described_class.perform_now(webhook_event.id, webhook_endpoint.id)
        }.to have_enqueued_job(described_class)

        expect(webhook_event.reload.status).to eq("failed")
      end
    end

    context "with missing event" do
      it "handles gracefully" do
        expect {
          described_class.perform_now(999999, webhook_endpoint.id)
        }.not_to raise_error
      end
    end

    context "with missing endpoint" do
      it "handles gracefully" do
        expect {
          described_class.perform_now(webhook_event.id, 999999)
        }.not_to raise_error
      end
    end
  end

  describe "job configuration" do
    it "is enqueued in the webhooks queue" do
      expect(described_class.new.queue_name).to eq("webhooks")
    end
  end
end
