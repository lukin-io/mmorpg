# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clan do
  describe "#recruitment_questions" do
    it "returns default questions from config" do
      clan = create(:clan)

      expect(clan.recruitment_questions).to match_array(Rails.configuration.x.clans.dig("recruitment", "default_vetting_questions"))
    end
  end

  describe "#withdrawal_limit_for" do
    it "returns configured limits per role/currency" do
      clan = create(:clan)
      limits = Rails.configuration.x.clans.dig("treasury", "withdrawal_limits")

      expect(clan.withdrawal_limit_for(:leader, :gold)).to eq(limits.dig("leader", "gold"))
    end
  end
end
