# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClanPolicy do
  subject(:policy) { described_class.new(user, clan) }

  let(:clan) { create(:clan) }
  let(:user) { create(:user) }

  context "with a warlord membership" do
    before { create(:clan_membership, clan: clan, user: user, role: :warlord) }

    it "allows war declarations" do
      expect(policy.declare_war?).to be(true)
      expect(policy.manage_treasury?).to be(false)
    end
  end

  context "with a quartermaster membership" do
    before { create(:clan_membership, clan: clan, user: user, role: :quartermaster) }

    it "allows treasury management" do
      expect(policy.manage_treasury?).to be(true)
    end
  end
end
