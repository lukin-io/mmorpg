# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcApplicationService do
  let(:service) { described_class.new }
  let(:arena_room) { create(:arena_room, slug: "training", level_min: 0, level_max: 5) }

  describe "#create_for_room" do
    context "with valid room" do
      it "creates an NPC application" do
        result = service.create_for_room(room: arena_room)

        expect(result.success?).to be true
        expect(result.application).to be_persisted
        expect(result.application.npc_application?).to be true
        expect(result.application.status).to eq("open")
      end

      it "uses the captured mannequin application contract in the training room" do
        result = service.create_for_room(room: arena_room)

        expect(result.application.applicant_name).to eq("Манекен")
        expect(result.application.applicant_level).to eq(1)
        expect(result.application.fight_kind).to eq("free")
        expect(result.application.timeout_seconds).to eq(300)
        expect(result.application.trauma_percent).to eq(30)
        expect(result.application.team_level_min).to eq(0)
        expect(result.application.team_level_max).to eq(5)
        expect(result.application.enemy_level_min).to eq(0)
        expect(result.application.enemy_level_max).to eq(33)
        expect(result.application.metadata["neverlands_rule_value"]).to eq(10)
      end

      it "uses the captured NPC without random selection" do
        npc1 = Game::World::ArenaNpcConfig.sample_npc("training")
        npc2 = Game::World::ArenaNpcConfig.sample_npc("training")

        expect(npc1[:key]).to eq(npc2[:key])
      end

      it "does not attach generic difficulty metadata" do
        result = service.create_for_room(room: arena_room)

        expect(result.success?).to be true
        expect(result.application.applicant_name).to eq("Манекен")
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
        expect(result2.errors).to include("У этого бота уже есть открытая заявка")
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

      expect(names).to eq(["Манекен"])
    end
  end
end
