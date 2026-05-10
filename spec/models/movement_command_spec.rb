# frozen_string_literal: true

require "rails_helper"

RSpec.describe MovementCommand, type: :model do
  describe "travel lifecycle validations" do
    it "requires an action key for offered movement" do
      command = build(:movement_command, :offered, action_key: nil)

      expect(command).not_to be_valid
      expect(command.errors[:action_key]).to include("can't be blank")
    end

    it "allows legacy queued commands without travel fields" do
      command = build(:movement_command, status: :queued, action_key: nil, travel_seconds: nil)

      expect(command).to be_valid
    end
  end

  describe "position helpers" do
    let(:command) do
      build(
        :movement_command,
        :offered,
        from_x: 4,
        from_y: 5,
        target_x: 4,
        target_y: 6,
        predicted_x: 4,
        predicted_y: 6
      )
    end

    it "exposes source, target, and predicted coordinates" do
      expect(command.source_position).to eq([4, 5])
      expect(command.target_position).to eq([4, 6])
      expect(command.predicted_position).to eq([4, 6])
    end
  end

  describe "#expired_offer?" do
    it "is true only for stale offered commands" do
      stale_offer = create(:movement_command, :offered, created_at: described_class::OFFER_TTL.ago - 1.second)
      moving_command = create(:movement_command, :moving, created_at: described_class::OFFER_TTL.ago - 1.second)

      expect(stale_offer).to be_expired_offer
      expect(moving_command).not_to be_expired_offer
    end
  end

  describe "#remaining_seconds" do
    it "returns the remaining travel time for active movement" do
      command = build(:movement_command, :moving, ends_at: 12.seconds.from_now)

      expect(command.remaining_seconds).to be_between(1, 12).inclusive
    end

    it "does not return negative values for overdue movement" do
      command = build(:movement_command, :moving, ends_at: 1.second.ago)

      expect(command.remaining_seconds).to eq(0)
    end
  end
end
