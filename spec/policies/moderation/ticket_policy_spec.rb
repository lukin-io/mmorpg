require "rails_helper"

RSpec.describe Moderation::TicketPolicy do
  subject(:policy) { described_class.new(user, ticket) }

  let(:reporter) { create(:user) }
  let(:ticket) { create(:moderation_ticket, reporter:) }

  context "for reporter" do
    let(:user) { reporter }

    it "allows viewing and appealing but not updating" do
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.appeal?).to be(true)
      expect(policy.update?).to be(false)
    end
  end

  context "for moderator" do
    let(:user) { create(:user, :moderator) }

    it "allows full access" do
      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
    end
  end
end
