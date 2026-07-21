# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorldActionOfferPolicy do
  subject(:policy) { described_class.new(user, offer) }

  let(:owner) { create(:user) }
  let(:character) { create(:character, user: owner) }
  let(:offer) { build(:world_action_offer, character:) }

  describe "#accept?" do
    context "when the user owns the offer's character" do
      let(:user) { owner }

      it { is_expected.to be_accept }

      it "authorizes the same owned offer for a city hotspot target" do
        city_offer = build(:world_action_offer, :city_transition, character:)

        expect(described_class.new(user, city_offer)).to be_accept
      end
    end

    context "when the offer belongs to another user's character" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_accept }
    end

    context "when the user is nil" do
      let(:user) { nil }

      it { is_expected.not_to be_accept }
    end

    context "when the offer has no character" do
      let(:user) { owner }
      let(:offer) { build(:world_action_offer, :without_target, character: nil) }

      it { is_expected.not_to be_accept }
    end
  end
end
