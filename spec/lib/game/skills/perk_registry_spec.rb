# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PerkRegistry do
  describe ".find" do
    it "returns perk definition for valid key" do
      perk = described_class.find(:berserker)

      expect(perk).to be_present
      expect(perk[:key]).to eq(:berserker)
      expect(perk[:name]).to eq("Berserker")
      expect(perk[:category]).to eq(:combat)
    end

    it "returns nil for invalid key" do
      expect(described_class.find(:nonexistent)).to be_nil
    end

    it "accepts string keys" do
      perk = described_class.find("berserker")

      expect(perk).to be_present
      expect(perk[:key]).to eq(:berserker)
    end
  end

  describe ".all_keys" do
    it "returns array of all perk keys" do
      keys = described_class.all_keys

      expect(keys).to be_an(Array)
      expect(keys).to include(:berserker, :guardian, :assassin)
    end
  end

  describe ".by_category" do
    it "returns combat perks" do
      combat_perks = described_class.by_category(:combat)

      expect(combat_perks).to all(satisfy { |p| p[:category] == :combat })
      expect(combat_perks.map { |p| p[:key] }).to include(:berserker, :guardian)
    end

    it "returns magic perks" do
      magic_perks = described_class.by_category(:magic)

      expect(magic_perks).to all(satisfy { |p| p[:category] == :magic })
      expect(magic_perks.map { |p| p[:key] }).to include(:pyromancer, :cryomancer)
    end

    it "returns empty array for invalid category" do
      expect(described_class.by_category(:invalid)).to be_empty
    end
  end

  describe ".valid?" do
    it "returns true for valid perks" do
      expect(described_class.valid?(:berserker)).to be true
      expect(described_class.valid?("guardian")).to be true
    end

    it "returns false for invalid perks" do
      expect(described_class.valid?(:nonexistent)).to be false
    end
  end

  describe ".excluded_by" do
    it "returns perks excluded by berserker" do
      excluded = described_class.excluded_by(:berserker)

      expect(excluded).to include(:guardian, :tactician)
    end

    it "returns empty array for perks with no exclusions" do
      excluded = described_class.excluded_by(:veteran)

      expect(excluded).to be_empty
    end

    it "returns empty array for invalid perk" do
      expect(described_class.excluded_by(:nonexistent)).to be_empty
    end
  end

  describe ".mutually_exclusive?" do
    it "returns true for mutually exclusive perks" do
      expect(described_class.mutually_exclusive?(:berserker, :guardian)).to be true
      expect(described_class.mutually_exclusive?(:pyromancer, :cryomancer)).to be true
    end

    it "returns false for non-exclusive perks" do
      expect(described_class.mutually_exclusive?(:berserker, :veteran)).to be false
      expect(described_class.mutually_exclusive?(:lucky, :veteran)).to be false
    end

    it "works regardless of order" do
      expect(described_class.mutually_exclusive?(:guardian, :berserker)).to be true
    end
  end

  describe ".available_for" do
    def mock_character(level:, perks: {}, perk_points: 3)
      obj = Object.new
      obj.define_singleton_method(:level) { level }
      obj.define_singleton_method(:perks) { perks }
      obj.define_singleton_method(:perk_points_available) { perk_points }
      obj
    end

    let(:character) { mock_character(level: 15, perks: {}, perk_points: 3) }

    it "returns perks the character can select" do
      available = described_class.available_for(character)

      expect(available).to be_an(Array)
      expect(available.map { |p| p[:key] }).to include(:berserker, :veteran)
    end

    it "filters by level requirement" do
      low_level_char = mock_character(level: 3, perks: {}, perk_points: 1)
      available = described_class.available_for(low_level_char)

      # Only level 5 perks should be unavailable at level 3
      expect(available).to be_empty
    end

    context "with selected perks" do
      let(:character_with_perks) do
        mock_character(level: 15, perks: {"berserker" => "2024-01-01"}, perk_points: 2)
      end

      it "excludes already selected perks" do
        available = described_class.available_for(character_with_perks)

        expect(available.map { |p| p[:key] }).not_to include(:berserker)
      end

      it "excludes mutually exclusive perks" do
        available = described_class.available_for(character_with_perks)

        # Guardian and tactician are excluded by berserker
        expect(available.map { |p| p[:key] }).not_to include(:guardian, :tactician)
      end
    end
  end

  describe ".can_select?" do
    def mock_character(level:, perks: {}, perk_points: 3)
      obj = Object.new
      obj.define_singleton_method(:level) { level }
      obj.define_singleton_method(:perks) { perks }
      obj.define_singleton_method(:perk_points_available) { perk_points }
      obj
    end

    let(:character) { mock_character(level: 15, perks: {}, perk_points: 3) }

    it "returns allowed: true for valid selection" do
      result = described_class.can_select?(character, :berserker)

      expect(result[:allowed]).to be true
      expect(result[:reason]).to be_nil
    end

    it "rejects perks above level requirement" do
      low_level_char = mock_character(level: 3, perks: {}, perk_points: 1)
      result = described_class.can_select?(low_level_char, :berserker)

      expect(result[:allowed]).to be false
      expect(result[:reason]).to include("level")
    end

    it "rejects already selected perks" do
      char_with_perk = mock_character(level: 15, perks: {"berserker" => "2024-01-01"}, perk_points: 2)
      result = described_class.can_select?(char_with_perk, :berserker)

      expect(result[:allowed]).to be false
      expect(result[:reason]).to include("already selected")
    end

    it "rejects excluded perks" do
      char_with_berserker = mock_character(level: 15, perks: {"berserker" => "2024-01-01"}, perk_points: 2)
      result = described_class.can_select?(char_with_berserker, :guardian)

      expect(result[:allowed]).to be false
      expect(result[:reason]).to include("Excluded")
    end

    it "rejects when no perk points available" do
      char_no_points = mock_character(level: 15, perks: {}, perk_points: 0)
      result = described_class.can_select?(char_no_points, :berserker)

      expect(result[:allowed]).to be false
      expect(result[:reason]).to include("perk points")
    end

    it "rejects invalid perk key" do
      result = described_class.can_select?(character, :nonexistent)

      expect(result[:allowed]).to be false
      expect(result[:reason]).to include("not found")
    end
  end

  describe ".perk_points_at_level" do
    it "calculates perk points correctly" do
      expect(described_class.perk_points_at_level(1)).to eq(0)
      expect(described_class.perk_points_at_level(5)).to eq(1)
      expect(described_class.perk_points_at_level(10)).to eq(2)
      expect(described_class.perk_points_at_level(25)).to eq(5)
    end
  end

  describe ".grouped_by_category" do
    it "groups perks by category" do
      grouped = described_class.grouped_by_category

      expect(grouped).to have_key(:combat)
      expect(grouped).to have_key(:magic)
      expect(grouped).to have_key(:defense)
      expect(grouped).to have_key(:utility)

      expect(grouped[:combat]).to all(satisfy { |p| p[:category] == :combat })
    end
  end

  describe "perk definitions" do
    it "all perks have required fields" do
      described_class.all.each do |key, perk|
        expect(perk[:key]).to eq(key), "#{key} has mismatched key"
        expect(perk[:name]).to be_present, "#{key} missing name"
        expect(perk[:description]).to be_present, "#{key} missing description"
        expect(perk[:category]).to be_present, "#{key} missing category"
        expect(perk[:level_required]).to be_a(Integer), "#{key} missing level_required"
        expect(perk[:effects]).to be_a(Hash), "#{key} missing effects"
        expect(perk[:excludes]).to be_an(Array), "#{key} missing excludes"
      end
    end

    it "all exclusions are bidirectional or valid" do
      described_class.all.each do |key, perk|
        perk[:excludes].each do |excluded_key|
          expect(described_class.valid?(excluded_key)).to be(true),
            "#{key} excludes invalid perk #{excluded_key}"
        end
      end
    end
  end
end
