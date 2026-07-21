# frozen_string_literal: true

require "rails_helper"

RSpec.describe CharacterPosition, type: :model do
  describe "authoritative region coordinates" do
    it "accepts the origin and final cell of the MVP region" do
      expect(build(:character_position, :at_origin)).to be_valid
      expect(build(:character_position, :at_region_edge)).to be_valid
    end

    it "rejects coordinates equal to or beyond the region dimensions" do
      position = build(:character_position, :outside_region)

      expect(position).not_to be_valid
      expect(position.errors[:x]).to include("must be within zone bounds")
      expect(position.errors[:y]).to include("must be within zone bounds")
    end

    it "rejects negative and null coordinates" do
      negative = build(:character_position, x: -1, y: 0)
      null = build(:character_position, x: nil, y: 0)

      expect(negative).not_to be_valid
      expect(negative.errors[:x]).to include("must be within zone bounds")
      expect(null).not_to be_valid
      expect(null.errors[:x]).to be_present
    end
  end

  describe "#ready_for_action?" do
    it "is ready with no previous action or after the cooldown" do
      position = build(:character_position, last_action_at: nil)
      cooled_down = build(:character_position, last_action_at: 31.seconds.ago)

      expect(position.ready_for_action?(cooldown_seconds: 30)).to be true
      expect(cooled_down.ready_for_action?(cooldown_seconds: 30)).to be true
    end

    it "is not ready during the cooldown" do
      position = build(:character_position, last_action_at: 5.seconds.ago)

      expect(position.ready_for_action?(cooldown_seconds: 30)).to be false
    end
  end
end
