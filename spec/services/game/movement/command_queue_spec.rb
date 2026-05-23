require "rails_helper"

RSpec.describe Game::Movement::CommandQueue do
  let(:zone) { create(:zone, width: 3, height: 3) }
  let!(:spawn_point) { create(:spawn_point, zone:, x: 0, y: 0, default_entry: true) }
  let!(:tile_origin) { MapTileTemplate.create!(zone: zone.name, x: 0, y: 0, terrain_type: "outdoor", passable: true) }
  let!(:tile_east) { MapTileTemplate.create!(zone: zone.name, x: 1, y: 0, terrain_type: "outdoor", passable: true) }
  let(:character) { create(:character, alignment: "none") }
  let(:queue) { described_class.new(character:) }

  before do
    create(:character_position, character:, zone:, x: 0, y: 0)
    @previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  after { ActiveJob::Base.queue_adapter = @previous_adapter }

  describe "#enqueue" do
    it "records a server movement offer and enqueues the processor job" do
      expect { queue.enqueue(direction: :east) }.to change(MovementCommand, :count).by(1)

      command = MovementCommand.last
      expect(command).to be_offered
      expect(command.source_position).to eq([0, 0])
      expect(command.target_position).to eq([1, 0])
      expect(command.predicted_x).to eq(1)
      expect(command.predicted_y).to eq(0)
      expect(command.action_key).to be_present
      expect(command.travel_seconds).to eq(30)
      expect(command.metadata["terrain_type"]).to eq("outdoor")

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      expect(job[:job]).to eq(Game::MovementCommandProcessorJob)
      expect(job[:args]).to include(command.id)
    end
  end

  describe "#process" do
    it "accepts the authoritative move without finalizing coordinates immediately" do
      command = queue.enqueue(direction: :east)

      queue.process(command.id)
      command.reload

      expect(command).to be_moving
      expect(command.started_at).to be_present
      expect(command.ends_at).to be > command.started_at
      expect(character.reload.position.x).to eq(0)
    end

    it "finalizes accepted travel through the completion service after its timer" do
      command = queue.enqueue(direction: :east)
      queue.process(command.id)
      command.reload.update!(ends_at: 1.second.ago)

      Game::Movement::CompleteMove.new(character:).call

      expect(command.reload).to be_completed
      expect(character.reload.position.x).to eq(1)
    end
  end
end
