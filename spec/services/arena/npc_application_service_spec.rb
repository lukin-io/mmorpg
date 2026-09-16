# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcApplicationService do
  let(:service) { described_class.new }
  let(:arena_room) { create(:arena_room, slug: "training", level_min: 0, level_max: 5) }

  describe "#create_for_room" do
    it "retires an expired offer and recovers exactly once after delayed jobs" do
      old = service.create_for_room(room: arena_room).application
      old.update!(expires_at: Time.current)
      replacement = service.create_for_room(room: arena_room)
      expect(replacement.success?).to be(true)
      expect(old.reload).to be_expired
      expect(service.create_for_room(room: arena_room).success?).to be(false)
      expect(arena_room.arena_applications.open.count).to eq(1)
    end

    it "does not announce an offer rolled back by its caller" do
      expect(ActionCable.server).not_to receive(:broadcast)
      ArenaRoom.transaction do
        expect(service.create_for_room(room: arena_room).success?).to be(true)
        raise ActiveRecord::Rollback
      end
      expect(ArenaApplication.from_npcs).to be_empty
    end

    it "rejects disabled or full rooms" do
      arena_room.update!(active: false)
      expect(service.create_for_room(room: arena_room).success?).to be(false)
      arena_room.update!(active: true, max_concurrent_matches: 1)
      create(:arena_match, arena_room:, status: :live)
      expect(service.create_for_room(room: arena_room).errors).to include("Arena room is full")
      expect(arena_room.arena_applications).to be_empty
    end

    it "serializes independent concurrent replenishment calls", js: true do
      room_id = arena_room.id
      ready = Queue.new
      start = Queue.new
      workers = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << true
            start.pop
            described_class.new.create_for_room(room: ArenaRoom.find(room_id))
          end
        end
      end
      2.times { ready.pop }
      2.times { start << true }
      results = workers.map(&:value)
      expect(results.count(&:success?)).to eq(1)
      expect(ArenaApplication.open.where(arena_room_id: room_id).count).to eq(1)
      expect(NpcTemplate.where(npc_key: "arena_training_dummy").count).to eq(1)
    end

    it "rejects a direct duplicate insert at the database boundary" do
      application = service.create_for_room(room: arena_room).application
      expect do
        ArenaApplication.transaction(requires_new: true) { application.dup.save!(validate: false) }
      end.to raise_error(ActiveRecord::RecordNotUnique)
      expect(arena_room.arena_applications.open.count).to eq(1)
    end

    context "with valid room" do
      it "creates an NPC application" do
        result = service.create_for_room(room: arena_room)

        expect(result.success?).to be true
        expect(result.application).to be_persisted
        expect(result.application.npc_application?).to be true
        expect(result.application.status).to eq("open")
      end

      it "keeps the Dummy open-side gate independent of a higher hall range" do
        arena_room.update!(level_min: 5, level_max: 10)
        application = service.create_for_room(room: arena_room).application
        expect(application).to have_attributes(team_level_min: 0, team_level_max: 5)
        expect(application.acceptable_by?(create(:character, level: 5))).to be(true)
        expect(application.acceptable_by?(create(:character, level: 6))).to be(false)
      end

      it "uses the captured mannequin application contract in the training room" do
        result = service.create_for_room(room: arena_room)

        expect(result.application.applicant_name).to eq("Training Dummy")
        expect(result.application.applicant_level).to eq(1)
        expect(result.application.fight_kind).to eq("free")
        expect(result.application.timeout_seconds).to eq(300)
        expect(result.application.trauma_percent).to eq(30)
        expect(result.application.team_level_min).to eq(0)
        expect(result.application.team_level_max).to eq(5)
        expect(result.application.enemy_level_min).to eq(0)
        expect(result.application.enemy_level_max).to eq(33)
        expect(result.application.metadata["neverlands_rule_value"]).to eq(10)
        expect(result.application.npc_template.metadata.dig("combat_profile", "injected_attack_keys")).to eq(
          %w[spirit_arrow mind_blast]
        )
        expect(result.application.npc_template.metadata.dig("combat_profile", "injected_block_keys")).to eq(
          %w[magic_shield rainbow_barrier crystal_sphere]
        )
      end

      it "uses the captured NPC without random selection" do
        npc1 = Game::World::ArenaNpcConfig.sample_npc("training")
        npc2 = Game::World::ArenaNpcConfig.sample_npc("training")

        expect(npc1[:key]).to eq(npc2[:key])
      end

      it "does not attach generic difficulty metadata" do
        result = service.create_for_room(room: arena_room)

        expect(result.success?).to be true
        expect(result.application.applicant_name).to eq("Training Dummy")
        expect(result.application.metadata).not_to have_key("difficulty")
      end

      it "broadcasts new application" do
        expect(ActionCable.server).to receive(:broadcast).with(
          "arena:room:#{arena_room.id}",
          hash_including(type: "new_application")
        )

        service.create_for_room(room: arena_room)
      end
    end

    context "with invalid room" do
      it "fails when room has no NPC config" do
        # Stub the config to return empty for this specific room
        allow(Game::World::ArenaNpcConfig).to receive(:sample_npc)
          .with("empty_room")
          .and_return(nil)

        empty_room = create(:arena_room, slug: "empty_room", level_min: 50, level_max: 100)
        result = service.create_for_room(room: empty_room)

        expect(result.success?).to be false
        expect(result.errors).to include("No NPC available for this room")
      end
    end

    context "when NPC already has open application" do
      it "prevents duplicate applications" do
        # Create first application
        result1 = service.create_for_room(room: arena_room)
        expect(result1.success?).to be true

        # Try to create another with same NPC
        npc = result1.application.npc_template
        result2 = service.create_with_template(room: arena_room, npc_template: npc)

        expect(result2.success?).to be false
        expect(result2.errors).to include("This NPC already has an open application")
      end
    end
  end

  describe "#create_with_template" do
    let(:npc_template) do
      create(:npc_template,
        role: "arena_bot",
        name: "Test Bot",
        level: 5,
        metadata: {"ai_behavior" => "passive"})
    end

    it "creates application for specific NPC" do
      result = service.create_with_template(room: arena_room, npc_template: npc_template)

      expect(result.success?).to be true
      expect(result.application.npc_template).to eq(npc_template)
    end

    it "fails for non-arena-bot NPCs" do
      hostile_npc = create(:npc_template, role: "hostile", name: "Plague Rat")
      result = service.create_with_template(room: arena_room, npc_template: hostile_npc)

      expect(result.success?).to be false
      expect(result.errors).to include("NPC template is not an arena bot")
    end
  end

  describe "#spawn_batch" do
    it "creates multiple NPC applications" do
      results = service.spawn_batch(room: arena_room, count: 3)

      expect(results.length).to eq(3)
      successful = results.select(&:success?)
      expect(successful.length).to eq(1)
    end

    it "keeps training batch focused on the captured mannequin" do
      results = service.spawn_batch(room: arena_room, count: 3)
      names = results.map { |r| r.application&.applicant_name }.compact

      expect(names).to eq(["Training Dummy"])
    end
  end
end
