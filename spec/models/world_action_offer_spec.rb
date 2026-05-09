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
end
