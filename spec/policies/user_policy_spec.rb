require "rails_helper"

RSpec.describe UserPolicy do
  let(:record) { create(:user) }

  describe "#index?" do
    it "allows moderators" do
      user = create(:user).tap { |u| u.add_role(:moderator) }

      expect(described_class.new(user, record).index?).to be(true)
    end

    it "denies regular players" do
      user = create(:user)

      expect(described_class.new(user, record).index?).to be(false)
    end
  end

  describe "#update?" do
    it "allows GMs" do
      user = create(:user).tap { |u| u.add_role(:gm) }

      expect(described_class.new(user, record).update?).to be(true)
    end

    it "denies moderators" do
      user = create(:user).tap { |u| u.add_role(:moderator) }

      expect(described_class.new(user, record).update?).to be(false)
    end
  end

  describe "#destroy?" do
    it "allows admins" do
      user = create(:user).tap { |u| u.add_role(:admin) }

      expect(described_class.new(user, record).destroy?).to be(true)
    end

    it "denies GMs" do
      user = create(:user).tap { |u| u.add_role(:gm) }

      expect(described_class.new(user, record).destroy?).to be(false)
    end
  end
end
