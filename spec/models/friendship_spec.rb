require "rails_helper"

RSpec.describe Friendship, type: :model do
  describe "validations" do
    it "prevents self-friendship" do
      user = create(:user)
      friendship = build(:friendship, requester: user, receiver: user)

      expect(friendship).not_to be_valid
      expect(friendship.errors[:receiver_id]).to include("cannot be the same as requester")
    end
  end

  describe "#accept!" do
    it "marks the friendship as accepted" do
      friendship = create(:friendship)

      friendship.accept!

      expect(friendship).to be_accepted
      expect(friendship.accepted_at).to be_present
    end
  end
end
