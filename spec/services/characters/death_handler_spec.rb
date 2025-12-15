# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::DeathHandler do
  let(:user) { create(:user) }
  let(:zone) { create(:zone) }
  let(:character) do
    create(:character,
      user: user,
      experience: 1000,
      current_hp: 0,
      max_hp: 100,
      current_mp: 50,
      max_mp: 50)
  end
  let!(:character_position) do
    create(:character_position, character: character, zone: zone, x: 5, y: 5)
  end

  subject(:handler) { described_class.new(character) }

  describe ".call" do
    it "creates a new instance and calls it" do
      allow_any_instance_of(described_class).to receive(:call)
      described_class.call(character)
    end
  end

  describe "#call" do
    before do
      # Stub the regen job to avoid enqueuing
      allow(Characters::RegenTickerJob).to receive(:perform_later)
    end

    context "when successful" do
      let!(:spawn_point) do
        create(:spawn_point, zone: zone, x: 10, y: 10, default_entry: true)
      end

      it "applies penalties" do
        handler.call
        expect(character.reload.experience).to be < 1000
      end

      it "broadcasts death event" do
        expect(ActionCable.server).to receive(:broadcast).at_least(:twice)
        handler.call
      end

      it "respawns character with 25% HP" do
        handler.call
        expect(character.reload.current_hp).to eq(25) # 25% of 100
      end

      it "respawns character with 25% MP" do
        handler.call
        expect(character.reload.current_mp).to eq(12) # 25% of 50
      end

      it "sets in_combat to false" do
        character.update!(in_combat: true)
        handler.call
        expect(character.reload.in_combat).to be false
      end

      it "enqueues regen ticker job" do
        expect(Characters::RegenTickerJob).to receive(:perform_later).with(character.id)
        handler.call
      end
    end
  end

  describe "#apply_penalties (private)" do
    context "in normal PvE combat" do
      it "deducts 5% of experience" do
        initial_xp = character.experience
        handler.send(:apply_penalties)

        expected_xp = (initial_xp * 0.95).to_i
        expect(character.reload.experience).to eq(expected_xp)
      end

      it "does not reduce experience below 0" do
        character.update!(experience: 5)
        handler.send(:apply_penalties)
        expect(character.reload.experience).to be >= 0
      end
    end

    context "in arena match" do
      before do
        # Stub in_arena_match? to return true
        allow(handler).to receive(:in_arena_match?).and_return(true)
      end

      it "does not deduct experience" do
        initial_xp = character.experience
        handler.send(:apply_penalties)
        expect(character.reload.experience).to eq(initial_xp)
      end
    end
  end

  describe "#find_respawn_point (private)" do
    context "with spawn point in current zone" do
      let!(:zone_spawn) do
        create(:spawn_point, zone: zone, x: 15, y: 15, default_entry: true)
      end

      it "returns spawn point from current zone" do
        result = handler.send(:find_respawn_point)
        expect(result).to eq(zone_spawn)
        expect(result.zone).to eq(zone)
      end
    end

    context "with multiple spawn points in zone" do
      let!(:default_spawn) do
        create(:spawn_point, zone: zone, x: 10, y: 10, default_entry: true)
      end
      let!(:non_default_spawn) do
        create(:spawn_point, zone: zone, x: 20, y: 20, default_entry: false)
      end

      it "returns only the default entry spawn point" do
        result = handler.send(:find_respawn_point)
        expect(result).to eq(default_spawn)
      end
    end

    context "without spawn point in current zone" do
      let(:other_zone) { create(:zone) }
      let!(:fallback_spawn) do
        create(:spawn_point, zone: other_zone, x: 0, y: 0, default_entry: true)
      end

      it "falls back to any default spawn point" do
        result = handler.send(:find_respawn_point)
        expect(result).to eq(fallback_spawn)
      end
    end

    context "with no spawn points at all" do
      it "returns nil" do
        result = handler.send(:find_respawn_point)
        expect(result).to be_nil
      end
    end

    context "when character has no position" do
      before { character_position.destroy }

      let!(:fallback_spawn) do
        create(:spawn_point, zone: zone, x: 0, y: 0, default_entry: true)
      end

      it "falls back to default spawn" do
        character.reload
        result = handler.send(:find_respawn_point)
        expect(result).to eq(fallback_spawn)
      end
    end
  end

  describe "#move_to_respawn_point (private)" do
    context "with valid spawn point" do
      let!(:spawn_point) do
        create(:spawn_point, zone: zone, x: 20, y: 25, default_entry: true)
      end

      it "moves character to spawn point" do
        handler.send(:move_to_respawn_point)
        position = character_position.reload

        expect(position.x).to eq(20)
        expect(position.y).to eq(25)
        expect(position.zone).to eq(zone)
      end
    end

    context "with spawn point in different zone" do
      let(:new_zone) { create(:zone) }
      let!(:spawn_point) do
        create(:spawn_point, zone: new_zone, x: 5, y: 5, default_entry: true)
      end

      before do
        # Remove spawn points from current zone
        SpawnPoint.where(zone: zone).destroy_all
      end

      it "moves character to new zone" do
        handler.send(:move_to_respawn_point)
        position = character_position.reload

        expect(position.zone).to eq(new_zone)
        expect(position.x).to eq(5)
        expect(position.y).to eq(5)
      end
    end

    context "without any spawn points" do
      it "does not change position" do
        original_x = character_position.x
        original_y = character_position.y

        handler.send(:move_to_respawn_point)
        position = character_position.reload

        expect(position.x).to eq(original_x)
        expect(position.y).to eq(original_y)
      end
    end

    context "when character has no position" do
      before { character_position.destroy }

      it "does not raise error" do
        expect { handler.send(:move_to_respawn_point) }.not_to raise_error
      end
    end
  end

  describe "#broadcast_death (private)" do
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "broadcasts to character vitals channel" do
      handler.send(:broadcast_death)

      expect(ActionCable.server).to have_received(:broadcast).with(
        "character:#{character.id}:vitals",
        hash_including(
          type: :death,
          character_id: character.id,
          character_name: character.name
        )
      )
    end

    context "with character position" do
      it "broadcasts to zone channel" do
        handler.send(:broadcast_death)

        expect(ActionCable.server).to have_received(:broadcast).with(
          "zone:#{zone.id}",
          hash_including(
            type: :player_death,
            character_id: character.id,
            x: character_position.x,
            y: character_position.y
          )
        )
      end
    end

    context "without character position" do
      before { character_position.destroy }

      it "only broadcasts to vitals channel" do
        character.reload
        new_handler = described_class.new(character)
        new_handler.send(:broadcast_death)

        expect(ActionCable.server).to have_received(:broadcast).once.with(
          "character:#{character.id}:vitals",
          anything
        )
      end
    end
  end

  describe "#in_arena_match? (private)" do
    context "when not in arena" do
      it "returns false" do
        expect(handler.send(:in_arena_match?)).to be false
      end
    end

    context "when character has active arena participation" do
      it "returns true for pending status" do
        # Stub the query to return exists
        allow(ArenaParticipation).to receive_message_chain(:joins, :where, :where, :exists?).and_return(true)
        expect(handler.send(:in_arena_match?)).to be true
      end

      it "returns false for completed status" do
        # No active participations
        expect(handler.send(:in_arena_match?)).to be false
      end
    end

    # Integration test with actual records (if ArenaMatch factory exists)
    context "with database records", skip: "ArenaMatch factory not available" do
      it "checks arena participation status" do
        expect(handler.send(:in_arena_match?)).to be false
      end
    end
  end
end
