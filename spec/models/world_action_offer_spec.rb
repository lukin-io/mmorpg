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

    it "rejects nil, another zone, or another coordinate" do
      zone = create(:zone)
      other_zone = create(:zone)
      character = create(:character)
      offer = build(:world_action_offer, character:, zone:, x: 5, y: 5)

      expect(offer.matches_position?(nil)).to be false
      expect(offer.matches_position?(build(:character_position, character:, zone: other_zone, x: 5, y: 5))).to be false
      expect(offer.matches_position?(build(:character_position, character:, zone:, x: 6, y: 5))).to be false
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

    it "accepts every captured outdoor local action type" do
      %w[search_resources fish drink dig].each do |action_type|
        offer = build(:world_action_offer, action_type:)

        expect(offer).to be_valid
      end
    end

    it "accepts city transition, building-entry, and exit offers" do
      %w[city_transition enter_city_building exit_city].each do |action_type|
        expect(build(:world_action_offer, action_type:)).to be_valid
      end
    end

    it "accepts the final cell and rejects coordinates outside its region" do
      edge_offer = build(:world_action_offer, :at_region_edge)
      region = edge_offer.zone
      outside_offer = build(:world_action_offer, zone: region, x: 1000, y: 999)
      negative_offer = build(:world_action_offer, zone: region, x: -1, y: 0)

      expect(edge_offer).to be_valid
      expect(outside_offer).not_to be_valid
      expect(outside_offer.errors[:x]).to include("must be within zone bounds")
      expect(negative_offer).not_to be_valid
    end

    it "rejects null coordinates at the persistence boundary" do
      offer = build(:world_action_offer, x: nil, y: nil)

      expect(offer).not_to be_valid
      expect(offer.errors[:x]).to be_present
      expect(offer.errors[:y]).to be_present
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
