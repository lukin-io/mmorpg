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

    it "keeps accepted travel intact when another worker retries a stale offered instance" do
      command = queue.enqueue(direction: :east)
      stale_command = MovementCommand.find(command.id)
      queue.process(command.id)
      accepted_timing = command.reload.attributes.slice("started_at", "ends_at", "metadata")

      result = queue.process(stale_command)

      expect(result).to be_moving
      expect(command.reload.attributes.slice("started_at", "ends_at", "metadata")).to eq(accepted_timing)
      expect(character.reload.position.x).to eq(0)
    end

    it "does not turn a cancelled offer into a failure on a delayed retry" do
      command = queue.enqueue(direction: :east)
      command.update!(status: :cancelled)

      expect(queue.process(command.id)).to be_cancelled
      expect(command.reload.failed_at).to be_nil
    end

    it "rolls back processing when an unexpected failure leaves the job retryable" do
      command = queue.enqueue(direction: :east)
      allow_any_instance_of(Game::Movement::AcceptMove).to receive(:call).and_wrap_original do |original|
        original.call
        raise "temporary failure"
      end

      expect { queue.process(command.id) }.to raise_error(RuntimeError, "temporary failure")

      expect(command.reload).to be_offered
      expect(command.started_at).to be_nil
      expect(character.reload.position.x).to eq(0)
    end
  end
end
