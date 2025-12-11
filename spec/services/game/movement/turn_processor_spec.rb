require "rails_helper"

RSpec.describe Game::Movement::TurnProcessor do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Castleton", width: 3, height: 3, biome: "city") }
  let!(:spawn_point) { create(:spawn_point, zone:, x: 0, y: 0, default_entry: true) }
  let!(:tile_origin) { MapTileTemplate.create!(zone: zone.name, x: 0, y: 0, terrain_type: "plaza", passable: true, biome: "city") }
  let!(:tile_east) do
    MapTileTemplate.create!(
      zone: zone.name,
      x: 1,
      y: 0,
      terrain_type: "street",
      passable: true,
      biome: "city",
      metadata: {"movement_modifier" => "swamp"}
    )
  end
  let(:character) { create(:character, faction_alignment: "neutral") }

  before do
    create(:character_position, character:, zone:, x: 0, y: 0)
  end

  after { travel_back }

  it "moves the character one tile per turn and resolves encounters" do
    result = described_class.new(character:, direction: :east, rng: Random.new(1)).call

    expect(result.position.x).to eq(1)
    expect(result.position.last_turn_number).to eq(1)
    expect(result.encounter).to be_present
  end

  it "prevents double movement within the same cooldown window" do
    service = described_class.new(character:, direction: :east, rng: Random.new(1))
    service.call

    expect do
      service.call
    end.to raise_error(Game::Movement::TurnProcessor::MovementViolationError)
  end

  it "applies terrain modifiers to action cooldowns" do
    travel_to(Time.current) do
      described_class.new(character:, direction: :east, rng: Random.new(1)).call

      expect do
        described_class.new(character:, direction: :west, rng: Random.new(2)).call
      end.to raise_error(Game::Movement::TurnProcessor::MovementViolationError)

      travel 4.seconds

      expect do
        described_class.new(character:, direction: :west, rng: Random.new(3)).call
      end.not_to raise_error
    end
  end

  describe "diagonal movement" do
    let(:diag_zone) { create(:zone, name: "DiagonalTest", width: 5, height: 5, biome: "city") }
    let!(:diag_spawn_point) { create(:spawn_point, zone: diag_zone, x: 2, y: 2, default_entry: true) }
    let(:diag_character) { create(:character, faction_alignment: "neutral") }

    before do
      # Create tiles for all 8 directions around center (2,2)
      [[2, 2], [1, 2], [3, 2], [2, 1], [2, 3], [3, 1], [3, 3], [1, 3], [1, 1]].each do |x, y|
        MapTileTemplate.create!(zone: diag_zone.name, x: x, y: y, terrain_type: "plaza", passable: true, biome: "city")
      end

      # Remove any existing position and create at center
      diag_character.position&.destroy
      diag_character.reload
      create(:character_position, character: diag_character, zone: diag_zone, x: 2, y: 2)
    end

    it "moves northeast (x+1, y-1)" do
      travel_to(Time.current) do
        result = described_class.new(character: diag_character, direction: :northeast, rng: Random.new(1)).call

        expect(result.position.x).to eq(3)
        expect(result.position.y).to eq(1)
      end
    end

    it "moves southeast (x+1, y+1)" do
      travel_to(Time.current) do
        result = described_class.new(character: diag_character, direction: :southeast, rng: Random.new(1)).call

        expect(result.position.x).to eq(3)
        expect(result.position.y).to eq(3)
      end
    end

    it "moves southwest (x-1, y+1)" do
      travel_to(Time.current) do
        result = described_class.new(character: diag_character, direction: :southwest, rng: Random.new(1)).call

        expect(result.position.x).to eq(1)
        expect(result.position.y).to eq(3)
      end
    end

    it "moves northwest (x-1, y-1)" do
      travel_to(Time.current) do
        result = described_class.new(character: diag_character, direction: :northwest, rng: Random.new(1)).call

        expect(result.position.x).to eq(1)
        expect(result.position.y).to eq(1)
      end
    end
  end
end
