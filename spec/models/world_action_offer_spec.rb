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

    it "rejects the removed manual outdoor-NPC attack action" do
      offer = build(:world_action_offer, action_type: "attack_npc")

      expect(offer).not_to be_valid
      expect(offer.errors[:action_type]).to be_present
    end

    it "accepts city transition, building-entry, and exit offers" do
      %w[city_transition enter_city_building open_location_feature exit_city].each do |action_type|
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

  describe "Look Around timer metadata" do
    let(:now) { Time.current.change(usec: 0) }
    let(:offer) do
      build(:world_action_offer, :accepted, accepted_at: now,
        metadata: {
          "local_action_ends_at" => (now + 28.seconds).iso8601(6),
          "local_action_result" => "There is no useful vegetation in this area."
        })
    end

    it "parses the persisted deadline and computes remaining seconds from server time" do
      expect(offer).to be_valid
      expect(offer.local_action_ends_at).to eq(now + 28.seconds)
      expect(offer.local_action_remaining_seconds(at: now)).to eq(28)
      expect(offer.local_action_remaining_seconds(at: now + 27.5.seconds)).to eq(1)
      expect(offer.local_action_remaining_seconds(at: now + 28.seconds)).to eq(0)
      expect(offer.local_action_remaining_seconds(at: now + 29.seconds)).to eq(0)
      expect(offer.local_action_result).to eq("There is no useful vegetation in this area.")
    end

    it "rejects missing acceptance, malformed deadlines, and non-search timer metadata" do
      [nil, "invalid", 123, now.iso8601(6)].each do |deadline|
        offer.metadata["local_action_ends_at"] = deadline
        expect(offer).not_to be_valid
      end

      offer.metadata["local_action_ends_at"] = (now + 28.seconds).iso8601(6)
      offer.accepted_at = nil
      expect(offer).not_to be_valid

      offer.accepted_at = now
      offer.action_type = "enter_building"
      expect(offer).not_to be_valid
    end

    it "requires the immediate result on accepted timed work" do
      offer.metadata.delete("local_action_result")

      expect(offer).not_to be_valid
      expect(offer.errors[:metadata]).to include("must have a Look Around result")
    end

    it "returns no timer or result for ordinary offers" do
      ordinary_offer = build(:world_action_offer)

      expect(ordinary_offer.local_action_ends_at).to be_nil
      expect(ordinary_offer.local_action_remaining_seconds).to eq(0)
      expect(ordinary_offer.local_action_result).to be_nil
    end

    it "consumes the saved result once across stale instances without changing timing or work state" do
      offer.save!
      stale_offer = described_class.find(offer.id)
      result = offer.local_action_result

      expect(offer.consume_local_action_result!(at: now)).to eq(result)
      expect(stale_offer.consume_local_action_result!(at: now + 1.second)).to be_nil
      expect(offer.reload.metadata["local_action_result_delivered_at"]).to eq(now.iso8601(6))
      expect(offer).to have_attributes(local_action_result: result, local_action_ends_at: now + 28.seconds, status: "accepted")
    end

    it "permits an undelivered completed result and rejects cancelled, failed, and ordinary offers" do
      offer.save!
      offer.complete!
      expect(offer.consume_local_action_result!(at: now + 29.seconds)).to eq(offer.local_action_result)

      %w[cancelled failed offered].each do |state|
        candidate = create(:world_action_offer, status: state, metadata: {
          "local_action_ends_at" => (now + 28.seconds).iso8601(6), "local_action_result" => "Hidden result"
        })
        expect(candidate.consume_local_action_result!).to be_nil
      end
      ordinary_offer = create(:world_action_offer)
      expect(ordinary_offer.consume_local_action_result!).to be_nil
    end
  end
end
