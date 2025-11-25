# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clans::ApplicationPipeline do
  let(:clan) { create(:clan) }
  let(:actor) { create(:user) }
  subject(:service) { described_class.new(clan: clan, actor: actor) }

  describe "#submit!" do
    it "auto-accepts when clan rules are met" do
      character = create(:character, user: actor, level: Rails.configuration.x.clans.dig("recruitment", "auto_accept", "min_level") + 5)
      referral = create(:user)
      quest_answers = {"question_0" => "Ready"}

      application = service.submit!(
        answers: quest_answers,
        character: character,
        referral: referral
      )

      expect(application.reload.status).to eq("auto_accepted")
      expect(clan.clan_memberships.exists?(user: actor)).to be(true)
    end
  end

  describe "#review!" do
    let(:reviewer) { create(:clan_membership, clan: clan, role: :leader).user }

    it "creates a membership when approved" do
      application = clan.clan_applications.create!(applicant: actor, vetting_answers: {"motivation" => "For glory"}, status: :pending)

      described_class.new(clan: clan, actor: reviewer).review!(
        application: application,
        reviewer: reviewer,
        decision: :approved,
        reason: "Good fit"
      )

      expect(clan.clan_memberships.exists?(user: actor)).to be(true)
      expect(application.reload.status).to eq("approved")
    end
  end
end
