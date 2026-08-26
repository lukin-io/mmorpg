# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaMatchPolicy do
  let(:participant_user) { create(:user) }
  let(:participant) { create(:character, user: participant_user) }
  let(:outsider_user) { create(:user) }
  let(:match) { create(:arena_match, :live) }

  before do
    create(:arena_participation,
      arena_match: match,
      character: participant,
      user: participant_user,
      team: "a")
  end

  describe "#show?" do
    it "allows any authenticated viewer and rejects an anonymous viewer" do
      expect(described_class.new(outsider_user, match)).to be_show
      expect(described_class.new(nil, match)).not_to be_show
    end
  end

  describe "#action? and #claim_timeout?" do
    it "allows a live participant to submit turns, surrender, and timeout claims" do
      policy = described_class.new(participant_user, match)

      expect(policy).to be_action
      expect(policy).to be_claim_timeout
    end

    it "rejects a non-participant and an anonymous user" do
      expect(described_class.new(outsider_user, match)).not_to be_action
      expect(described_class.new(outsider_user, match)).not_to be_claim_timeout
      expect(described_class.new(nil, match)).not_to be_action
      expect(described_class.new(nil, match)).not_to be_claim_timeout
    end

    it "rejects participant mutation after completion" do
      match.update!(status: :completed, ended_at: Time.current)

      expect(described_class.new(participant_user, match)).not_to be_action
      expect(described_class.new(participant_user, match)).not_to be_claim_timeout
    end
  end

  describe "#finish?" do
    it "allows only a participant to reach the server-owned finish precondition" do
      match.update!(status: :completed, ended_at: Time.current)

      expect(described_class.new(participant_user, match)).to be_finish
      expect(described_class.new(outsider_user, match)).not_to be_finish
      expect(described_class.new(nil, match)).not_to be_finish
    end

    it "allows a live participant through authorization so the controller can reject premature finish" do
      expect(described_class.new(participant_user, match)).to be_finish
    end
  end
end
