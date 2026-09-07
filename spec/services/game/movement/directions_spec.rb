# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::Directions do
  describe ".adjacent?" do
    it "accepts exactly the eight cells around the current coordinate" do
      targets = described_class::OFFSETS.values.map { |dx, dy| [3 + dx, 2 + dy] }

      expect(targets).to contain_exactly(
        [2, 1], [3, 1], [4, 1],
        [2, 2],         [4, 2],
        [2, 3], [3, 3], [4, 3]
      )
      expect(targets).to all(satisfy do |target_x, target_y|
        described_class.adjacent?(from_x: 3, from_y: 2, target_x:, target_y:)
      end)
    end

    it "rejects the current cell, jumps, and incomplete coordinates" do
      expect(described_class.adjacent?(from_x: 3, from_y: 2, target_x: 3, target_y: 2)).to be(false)
      expect(described_class.adjacent?(from_x: 3, from_y: 2, target_x: 5, target_y: 2)).to be(false)
      expect(described_class.adjacent?(from_x: 3, from_y: 2, target_x: 4, target_y: 4)).to be(false)
      expect(described_class.adjacent?(from_x: 3, from_y: 2, target_x: nil, target_y: 3)).to be(false)
    end
  end

  describe ".matches?" do
    it "requires the direction label to match the one-cell coordinate delta" do
      expect(described_class.matches?(
        direction: :northeast,
        from_x: 3,
        from_y: 2,
        target_x: 4,
        target_y: 1
      )).to be(true)
      expect(described_class.matches?(
        direction: :north,
        from_x: 3,
        from_y: 2,
        target_x: 4,
        target_y: 1
      )).to be(false)
    end
  end
end
