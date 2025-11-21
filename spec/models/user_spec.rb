require "rails_helper"

RSpec.describe User, type: :model do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  it "supports role assignment" do
    user = create(:user)
    user.add_role(:admin)

    expect(user.has_role?(:admin)).to be(true)
  end

  it "assigns player role by default" do
    user = create(:user)

    expect(user.has_role?(:player)).to be(true)
  end

  describe "#verified_for_social_features?" do
    it "returns false when unconfirmed" do
      user = build(:user, confirmed_at: nil)

      expect(user.verified_for_social_features?).to be(false)
    end

    it "returns true when confirmed" do
      user = build(:user, confirmed_at: Time.current)

      expect(user.verified_for_social_features?).to be(true)
    end
  end

  describe "#moderator?" do
    it "is true when user has moderator-level role" do
      user = create(:user)
      user.add_role(:moderator)

      expect(user.moderator?).to be(true)
    end

    it "is false otherwise" do
      user = create(:user)

      expect(user.moderator?).to be(false)
    end
  end
end
