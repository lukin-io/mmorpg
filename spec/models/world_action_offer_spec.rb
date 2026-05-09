# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorldActionOffer, type: :model do
  describe "#matches_position?" do
    it "matches the same zone and coordinates" do
      zone = create(:zone)
      character = create(:character)
      position = create(:character_position, character:, zone:, x: 5, y: 5)
      offer = build(:world_action_offer, character:, zone:, x: 5, y: 5)

      expect(offer.matches_position?(position)).to be(true)
    end
  end

  describe "#expired?" do
    it "is true after expires_at" do
      offer = build(:world_action_offer, :expired)

      expect(offer).to be_expired
    end
  end

  describe "validations" do
    it "requires a supported action type and action key" do
      offer = build(:world_action_offer, action_type: "unsupported", action_key: nil)

      expect(offer).not_to be_valid
      expect(offer.errors[:action_type]).to be_present
      expect(offer.errors[:action_key]).to include("can't be blank")
    end
  end

  describe "status helpers" do
    it "records accepted, completed, and failed states" do
      offer = create(:world_action_offer)

      offer.accept!
      expect(offer).to be_accepted
      expect(offer.accepted_at).to be_present

      offer.complete!
      expect(offer).to be_completed
      expect(offer.completed_at).to be_present

      offer.fail!("Blocked")
      expect(offer).to be_failed
      expect(offer.error_message).to eq("Blocked")
    end
  end
end
