require "rails_helper"

RSpec.describe Game::Movement::TurnProcessor do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Outpost", width: 3, height: 3, location_type: "city") }
  let!(:spawn_point) { create(:spawn_point, zone:, x: 0, y: 0, default_entry: true) }
  let!(:tile_origin) { MapTileTemplate.create!(zone: zone.name, x: 0, y: 0, terrain_type: "city", passable: true) }
  let!(:tile_east) do
    MapTileTemplate.create!(
      zone: zone.name,
      x: 1,
      y: 0,
      terrain_type: "city",
      passable: true
    )
  end
  let(:character) { create(:character, alignment: "none") }

  before do
    create(:character_position, character:, zone:, x: 0, y: 0)
  end

  after { travel_back }

  it "moves the character one tile per turn" do
    result = described_class.new(character:, direction: :east, rng: Random.new(1)).call

    expect(result.position.x).to eq(1)
    expect(result.position.last_turn_number).to eq(1)
  end

  it "prevents double movement within the same cooldown window" do
    service = described_class.new(character:, direction: :east, rng: Random.new(1))
    service.call

    expect do
      service.call
    end.to raise_error(Game::Movement::TurnProcessor::MovementViolationError)
  end

  it "uses source-backed base action cooldown" do
    travel_to(Time.current) do
      described_class.new(character:, direction: :east, rng: Random.new(1)).call

      expect do
        described_class.new(character:, direction: :west, rng: Random.new(2)).call
      end.to raise_error(Game::Movement::TurnProcessor::MovementViolationError)

      travel 31.seconds

      expect do
        described_class.new(character:, direction: :west, rng: Random.new(3)).call
      end.not_to raise_error
    end
  end

  describe "diagonal movement" do
    let(:diag_zone) { create(:zone, name: "DiagonalTest", width: 5, height: 5, location_type: "city") }
    let!(:diag_spawn_point) { create(:spawn_point, zone: diag_zone, x: 2, y: 2, default_entry: true) }
    let(:diag_character) { create(:character, alignment: "none") }

    before do
      # Create tiles for all 8 directions around center (2,2)
      [[2, 2], [1, 2], [3, 2], [2, 1], [2, 3], [3, 1], [3, 3], [1, 3], [1, 1]].each do |x, y|
        MapTileTemplate.create!(zone: diag_zone.name, x: x, y: y, terrain_type: "city", passable: true)
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

  describe "wanderer skill cooldown reduction" do
    let(:wanderer_zone) { create(:zone, name: "WandererTest", width: 5, height: 5, location_type: "outdoor") }
    let!(:wanderer_spawn) { create(:spawn_point, zone: wanderer_zone, x: 2, y: 2, default_entry: true) }

    before do
      # Create tiles for movement
      [[2, 2], [3, 2], [1, 2]].each do |x, y|
        MapTileTemplate.create!(zone: wanderer_zone.name, x: x, y: y, terrain_type: "outdoor", passable: true)
      end
    end

    context "with wanderer at 0" do
      let(:slow_char) { create(:character, alignment: "none", passive_skills: {"wanderer" => 0}) }

      before do
        slow_char.position&.destroy
        slow_char.reload
        create(:character_position, character: slow_char, zone: wanderer_zone, x: 2, y: 2)
      end

      it "uses 30 second base cooldown" do
        travel_to(Time.current) do
          described_class.new(character: slow_char, direction: :east, rng: Random.new(1)).call

          # Should NOT be able to move again before 30 seconds
          travel 29.seconds
          expect do
            described_class.new(character: slow_char, direction: :west, rng: Random.new(2)).call
          end.to raise_error(Game::Movement::TurnProcessor::MovementViolationError)

          # Should be able to move after 30 seconds
          travel 2.seconds
          expect do
            described_class.new(character: slow_char, direction: :west, rng: Random.new(3)).call
          end.not_to raise_error
        end
      end
    end

    context "with wanderer at 100" do
      let(:fast_char) { create(:character, alignment: "none", passive_skills: {"wanderer" => 100}) }

      before do
        fast_char.position&.destroy
        fast_char.reload
        create(:character_position, character: fast_char, zone: wanderer_zone, x: 2, y: 2)
      end

      it "uses base cooldown until the Neverlands formula is captured" do
        travel_to(Time.current) do
          described_class.new(character: fast_char, direction: :east, rng: Random.new(1)).call

          # Should NOT be able to move again before 30 seconds
          travel 29.seconds
          expect do
            described_class.new(character: fast_char, direction: :west, rng: Random.new(2)).call
          end.to raise_error(Game::Movement::TurnProcessor::MovementViolationError)

          # Should be able to move after 30 seconds
          travel 2.seconds
          expect do
            described_class.new(character: fast_char, direction: :west, rng: Random.new(3)).call
          end.not_to raise_error
        end
      end
    end

    context "with wanderer at 50" do
      let(:mid_char) { create(:character, alignment: "none", passive_skills: {"wanderer" => 50}) }

      before do
        mid_char.position&.destroy
        mid_char.reload
        create(:character_position, character: mid_char, zone: wanderer_zone, x: 2, y: 2)
      end

      it "uses base cooldown until the Neverlands formula is captured" do
        travel_to(Time.current) do
          described_class.new(character: mid_char, direction: :east, rng: Random.new(1)).call

          # Should NOT be able to move again before 30 seconds
          travel 29.seconds
          expect do
            described_class.new(character: mid_char, direction: :west, rng: Random.new(2)).call
          end.to raise_error(Game::Movement::TurnProcessor::MovementViolationError)

          # Should be able to move after 30 seconds
          travel 2.seconds
          expect do
            described_class.new(character: mid_char, direction: :west, rng: Random.new(3)).call
          end.not_to raise_error
        end
      end
    end
  end
end
