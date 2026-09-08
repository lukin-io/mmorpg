# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpcTemplate, type: :model do
  describe "cell encounter references" do
    let(:member_template) { create(:npc_template, npc_key: "roster_member") }
    let(:anchor_template) { create(:npc_template, npc_key: "roster_anchor") }
    let(:roster_metadata) { {"active" => false, "encounter_rosters" => [{"key" => "group", "members" => [{"npc_key" => member_template.npc_key}]}]} }

    it "protects inactive roster-only dependencies from deletion and key changes" do
      anchor = create(:tile_npc, npc_template: anchor_template, npc_key: anchor_template.npc_key, metadata: roster_metadata)
      expect(member_template.tile_npcs).to be_empty

      expect(member_template.destroy).to be false
      expect(member_template.errors[:base]).to include("Cannot delete an NPC template referenced by cell encounter rosters")
      expect(member_template.update(npc_key: "renamed_member")).to be false
      expect(member_template.errors[:npc_key]).to include("cannot change while referenced by cell encounters")
      expect(member_template.reload.npc_key).to eq("roster_member")

      anchor.update!(metadata: {"active" => false})
      expect(member_template.update(npc_key: "renamed_member")).to be true
      expect(member_template.destroy).to be_destroyed
    end

    it "keeps display-name edits available while a stable key is referenced" do
      create(:tile_npc, npc_template: anchor_template, metadata: roster_metadata)

      expect(member_template.update(name: "Renamed display label")).to be true
    end

    # js selects truncation cleanup so separate PostgreSQL connections see the
    # setup. No browser is required for this model-level lock check.
    it "blocks a concurrent roster writer after retirement has locked the template", js: true do
      metadata = roster_metadata
      anchor_id = anchor_template.id
      member_id = member_template.id
      competing_result = nil
      subscriber = lambda do |event|
        next unless event.payload[:sql].include?('FROM "tile_npcs"') && event.payload[:sql].include?("metadata @>")

        worker = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            ApplicationRecord.transaction do
              connection.execute("SET LOCAL lock_timeout = '100ms'")
              TileNpc.create!(zone: "Outpost Surroundings", x: 1, y: 1, npc_key: "roster_anchor",
                npc_template_id: anchor_id, npc_role: "hostile", level: 1, metadata:)
            end
          rescue => error
            competing_result = error
          end
        end
        expect(worker.join(5)).to eq(worker)
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { member_template.destroy! }

      expect(competing_result).to be_a(ActiveRecord::LockWaitTimeout)
      expect(NpcTemplate.exists?(member_id)).to be false
      expect(TileNpc.count).to eq(0)
      expect(build(:tile_npc, npc_template: anchor_template, metadata:)).not_to be_valid
    end
  end

  describe "spawn timing metadata" do
    it "exposes respawn timing from template metadata" do
      npc = build(
        :npc_template,
        metadata: {"respawn_seconds" => "7200", "respawn_variance_seconds" => "0"}
      )

      expect(npc.respawn_seconds).to eq(7200)
      expect(npc.respawn_variance_seconds).to eq(0)
    end

    it "does not invent respawn timing when source timing is absent" do
      npc = build(:npc_template)

      expect(npc.respawn_seconds).to be_nil
      expect(npc.respawn_variance_seconds).to be_nil
    end
  end

  describe "concerns integration" do
    let(:hostile_npc) { create(:npc_template, level: 10, role: "hostile") }
    let(:arena_bot) { create(:npc_template, level: 10, role: "arena_bot") }

    describe "Npc::CombatStats" do
      it "includes CombatStats concern" do
        expect(hostile_npc).to respond_to(:combat_stats)
        expect(hostile_npc).to respond_to(:combat_stat)
        expect(hostile_npc).to respond_to(:max_hp)
        expect(hostile_npc).to respond_to(:attack_power)
        expect(hostile_npc).to respond_to(:defense_value)
        expect(hostile_npc).to respond_to(:attack_damage_range)
      end

      it "combat_stats returns consistent values" do
        stats1 = hostile_npc.combat_stats
        stats2 = hostile_npc.combat_stats

        expect(stats1).to eq(stats2)
      end
    end

    describe "Npc::Combatable" do
      it "includes Combatable concern" do
        expect(hostile_npc).to respond_to(:can_engage_combat?)
        expect(hostile_npc).to respond_to(:hostile?)
        expect(hostile_npc).to respond_to(:attackable?)
        expect(hostile_npc).to respond_to(:combat_behavior)
        expect(hostile_npc).to respond_to(:should_defend?)
        expect(hostile_npc).to respond_to(:roll_initiative)
        expect(hostile_npc).to respond_to(:loot_table)
        expect(hostile_npc).to respond_to(:xp_reward)
      end
    end

    describe "concern interaction" do
      it "roll_initiative uses combat_stat for agility" do
        agility = hostile_npc.combat_stat(:agility)
        initiative = hostile_npc.roll_initiative(rng: Random.new(42))

        expect(initiative).to be_between(agility + 1, agility + 10)
      end

      it "does not invent defend behavior without captured metadata" do
        expect(hostile_npc.should_defend?(current_hp_ratio: 0.01, rng: Random.new(1))).to be false
      end
    end
  end

  describe "source-backed accessors" do
    let(:npc) { create(:npc_template, level: 10, role: "hostile") }

    describe "#health" do
      it "delegates to explicit max_hp" do
        expect(npc.health).to eq(npc.max_hp)
      end

      it "reflects metadata overrides" do
        npc.update!(metadata: {"health" => 500})
        expect(npc.health).to eq(500)
      end
    end

    describe "#ai_behavior" do
      it "returns string version of combat_behavior" do
        expect(npc.ai_behavior).to eq("aggressive")
        expect(npc.ai_behavior).to be_a(String)
      end

      it "reflects metadata override" do
        npc.update!(metadata: {"ai_behavior" => "passive"})
        expect(npc.ai_behavior).to eq("passive")
      end
    end
  end

  describe "arena bot specific methods" do
    let(:arena_bot) { create(:npc_template, role: "arena_bot", metadata: {"arena_rooms" => ["training"], "avatar" => "🎯"}) }
    let(:hostile) { create(:npc_template, role: "hostile") }

    describe "#arena_bot?" do
      it "returns true for arena_bot role" do
        expect(arena_bot.arena_bot?).to be true
      end

      it "returns false for other roles" do
        expect(hostile.arena_bot?).to be false
      end
    end

    describe "#arena_rooms" do
      it "returns rooms from metadata" do
        expect(arena_bot.arena_rooms).to eq(["training"])
      end

      it "returns empty array when not specified" do
        expect(hostile.arena_rooms).to eq([])
      end
    end

    describe "#avatar_emoji" do
      it "returns avatar from metadata" do
        expect(arena_bot.avatar_emoji).to eq("🎯")
      end

      it "does not invent an avatar when not specified" do
        expect(hostile.avatar_emoji).to be_nil
      end
    end
  end

  describe "validations" do
    it "requires a name" do
      npc = build(:npc_template, name: nil)

      expect(npc).not_to be_valid
      expect(npc.errors[:name]).to be_present
    end
  end

  describe "metadata JSONB storage" do
    it "stores explicit stats" do
      npc = create(:npc_template, metadata: {"stats" => {"attack" => 1}})

      expect(npc.reload.metadata["stats"]["attack"]).to eq(1)
    end

    it "stores explicit avatar image" do
      npc = create(:npc_template, metadata: {"avatar_image" => "zombie.png"})

      expect(npc.reload.metadata["avatar_image"]).to eq("zombie.png")
    end
  end
end
