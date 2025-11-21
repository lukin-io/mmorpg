require "rails_helper"

RSpec.describe Friendship, type: :model do
  describe "validations" do
    it "prevents self-friendship" do
      user = create(:user)
      friendship = build(:friendship, requester: user, receiver: user)

      expect(friendship).not_to be_valid
      expect(friendship.errors[:receiver_id]).to include("cannot be the same as requester")
    end

    it "respects receiver privacy preferences" do
      receiver = create(:user, friend_request_privacy: :nobody)
      friendship = build(:friendship, receiver: receiver)

      expect(friendship).not_to be_valid
      expect(friendship.errors[:base]).to include("receiver is not accepting friend requests")
    end

    it "allows requests when users are allies" do
      receiver = create(:user, friend_request_privacy: :allies_only)
      clan = create(:clan)
      create(:clan_membership, clan: clan, user: receiver)
      requester = create(:user)
      create(:clan_membership, clan: clan, user: requester)

      friendship = build(:friendship, receiver: receiver, requester: requester)

      expect(friendship).to be_valid
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
