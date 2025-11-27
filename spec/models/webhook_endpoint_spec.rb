# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookEndpoint, type: :model do
  let(:user) { create(:user) }
  let(:integration_token) { create(:integration_token, user: user) }

  describe "validations" do
    subject { build(:webhook_endpoint, integration_token: integration_token) }

    it { is_expected.to be_valid }

    it "requires name" do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it "requires target_url" do
      subject.target_url = nil
      expect(subject).not_to be_valid
    end

    it "requires secret" do
      subject.secret = nil
      expect(subject).not_to be_valid
    end

    it "validates target_url is HTTP/HTTPS" do
      subject.target_url = "ftp://example.com"
      expect(subject).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:integration_token) }
    it { is_expected.to have_many(:webhook_events).dependent(:destroy) }
  end

  describe "scopes" do
    let!(:active_endpoint) do
      create(:webhook_endpoint,
        integration_token: integration_token,
        enabled: true,
        event_types: ["player.level_up"])
    end
    let!(:inactive_endpoint) do
      create(:webhook_endpoint,
        integration_token: integration_token,
        enabled: false)
    end

    describe ".active" do
      it "returns only enabled endpoints" do
        expect(described_class.active).to include(active_endpoint)
        expect(described_class.active).not_to include(inactive_endpoint)
      end
    end

    describe ".subscribed_to" do
      it "returns endpoints subscribed to event type" do
        expect(described_class.subscribed_to("player.level_up")).to include(active_endpoint)
      end

      it "excludes endpoints not subscribed" do
        expect(described_class.subscribed_to("other.event")).not_to include(active_endpoint)
      end
    end
  end
end
