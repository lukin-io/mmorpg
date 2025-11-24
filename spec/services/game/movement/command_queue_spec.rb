require "rails_helper"

RSpec.describe Game::Movement::CommandQueue do
  let(:zone) { create(:zone, width: 3, height: 3) }
  let!(:spawn_point) { create(:spawn_point, zone:, x: 0, y: 0, default_entry: true) }
  let!(:tile_origin) { MapTileTemplate.create!(zone: zone.name, x: 0, y: 0, terrain_type: "plaza", passable: true, biome: zone.biome) }
  let!(:tile_east) { MapTileTemplate.create!(zone: zone.name, x: 1, y: 0, terrain_type: "road", passable: true, biome: zone.biome) }
  let(:character) { create(:character, faction_alignment: "neutral") }
  let(:queue) { described_class.new(character:) }

  before do
    create(:character_position, character:, zone:, x: 0, y: 0)
    @previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  after { ActiveJob::Base.queue_adapter = @previous_adapter }

  describe "#enqueue" do
    it "records predicted coordinates and enqueues the processor job" do
      expect { queue.enqueue(direction: :east) }.to change(MovementCommand, :count).by(1)

      command = MovementCommand.last
      expect(command.predicted_x).to eq(1)
      expect(command.predicted_y).to eq(0)
      expect(command.metadata["terrain_type"]).to eq("road")

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      expect(job[:job]).to eq(Game::MovementCommandProcessorJob)
      expect(job[:args]).to include(command.id)
    end
  end

  describe "#process" do
    it "executes the authoritative move and marks the command processed" do
      command = queue.enqueue(direction: :east)

      queue.process(command.id)
      command.reload

      expect(command).to be_processed
      expect(character.reload.position.x).to eq(1)
    end
  end
end
