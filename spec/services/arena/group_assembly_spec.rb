# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::GroupAssembly do
  include ActiveSupport::Testing::TimeHelpers
  let(:room) { create(:arena_room, level_min: 0, level_max: 33) }
  let(:players) { Array.new(5) { create(:character, level: 10, current_hp: 100, max_hp: 100) } }
  let(:handler) { Arena::ApplicationHandler.new }
  let(:assembly) { described_class.new }
  let(:parameters) do
    {fight_type: "team_battle", fight_kind: "free", timeout_seconds: 120, trauma_percent: 10,
     wait_minutes: 5, team_count: 2, enemy_count: 2,
     team_level_min: 9, team_level_max: 11, enemy_level_min: 8, enemy_level_max: 12}
  end
  let(:application) { handler.create(character: players.first, room:, params: parameters).application }

  it "assembles real sides, waits until the deadline, starts once and preserves one combat pipeline" do
    expect(application.arena_application_memberships.sole.character).to eq(players[0])
    expect(assembly.join(application:, character: players[1], team: "a")).to be_success
    expect(assembly.join(application:, character: players[2], team: "b")).to be_success
    expect(assembly.join(application:, character: players[3], team: "b")).to be_success
    expect(players[3].waiting_arena_application).to eq(application)
    expect(assembly.settle(application:)).to be_nil
    expect(ArenaMatch.count).to eq(0)

    travel_to(application.expires_at, with_usec: true) do
      match = assembly.settle(application:)
      expect(match).to be_live
      expect(match.fight_timeout_seconds).to eq(300)
      expect(match.team_participants("a").pluck(:character_id)).to match_array(players.first(2).map(&:id))
      expect(match.team_participants("b").pluck(:character_id)).to match_array(players[2..3].map(&:id))
      expect(match.arena_participations.map { |entry| Arena::CombatProfile.for_participation(entry)["injected_attack_keys"] }).to all(eq([]))
      expect { assembly.settle(application:) }.not_to change(ArenaMatch, :count)
      expect(players.first.waiting_arena_application).to be_nil
    end
  end

  it "rejects duplicate, invalid-side, full-side and wrong-level joins without reserving another place" do
    expect(assembly.join(application:, character: players[0], team: "b")).not_to be_success
    expect(assembly.join(application:, character: players[1], team: "c")).not_to be_success
    expect(assembly.join(application:, character: players[1], team: "a")).to be_success
    expect(assembly.join(application:, character: players[2], team: "a")).not_to be_success
    players[2].update!(level: 13)
    expect(assembly.join(application:, character: players[2], team: "b")).not_to be_success
    expect(application.arena_application_memberships.count).to eq(2)
  end

  it "does not let a joined member create or accept an unrelated fight" do
    assembly.join(application:, character: players[1], team: "b")
    result = handler.create(character: players[1], room:, params: {fight_type: "duel", fight_kind: "free"})
    expect(result).not_to be_success
    duel = create(:arena_application, arena_room: room, applicant: players[2])
    expect(handler.accept(application: duel, acceptor: players[1])).not_to be_success
  end

  it "releases an individual place and releases everyone when the owner cancels" do
    assembly.join(application:, character: players[1], team: "b")
    expect(assembly.withdraw(application:, character: players[4])).not_to be_success
    expect(assembly.withdraw(application:, character: players[1])).to be_success
    expect(players[1].waiting_arena_application).to be_nil
    assembly.join(application:, character: players[2], team: "b")
    expect(assembly.withdraw(application:, character: players[0])).to be_success
    expect(application.reload).to be_cancelled
    expect(players[2].waiting_arena_application).to be_nil
  end

  it "expires an empty opposing side and never awards an empty fight" do
    travel_to(application.expires_at, with_usec: true) do
      expect { assembly.settle(application:) }.not_to change(ArenaMatch, :count)
      expect(application.reload).to be_expired
      expect(players[0].waiting_arena_application).to be_nil
      expect(assembly.join(application:, character: players[1], team: "b")).not_to be_success
    end
  end

  it "revalidates HP at start instead of trusting an earlier join" do
    assembly.join(application:, character: players[1], team: "b")
    players[1].update!(current_hp: 1)
    travel_to(application.expires_at, with_usec: true) { assembly.settle(application:) }
    expect(application.reload).to be_expired
    expect(ArenaMatch.count).to eq(0)
  end

  it "revalidates equipment at the deadline and rejects fractional level bounds" do
    expect(handler.create(character: players[0], room:, params: parameters.merge(enemy_level_min: "8.5"))).not_to be_success
    app = handler.create(character: players[0], room:, params: parameters.merge(fight_kind: "no_weapons")).application
    assembly.join(application: app, character: players[1], team: "b")
    create(:inventory_item, inventory: players[1].inventory, equipped: true, equipment_slot: "head")
    travel_to(app.expires_at, with_usec: true) { assembly.settle(application: app) }
    expect(app.reload).to be_expired
    expect(ArenaMatch.count).to eq(0)
  end

  it "admits only one concurrent contender for the last place", js: true do
    app = application
    contenders = players[1..2]
    gate = Queue.new
    results = contenders.map do |character|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          described_class.new.join(application: ArenaApplication.find(app.id), character: Character.find(character.id), team: "a").success?
        end
      end
    end
    2.times { gate << true }
    expect(results.map(&:value).count(true)).to eq(1)
    expect(app.reload.members_for("a").size).to eq(2)
  end

  it "rejects excluded modes, malformed capacities and unsupported duel kinds" do
    [{fight_type: "sacrifice"}, {team_count: 31}, {team_count: "1.5"}, {enemy_level_min: 13, enemy_level_max: 12},
      {fight_type: "duel", fight_kind: "alignment_vs_alignment"}].each do |invalid|
      expect(handler.create(character: players[0], room:, params: parameters.merge(invalid))).not_to be_success
    end
    normalized = handler.create(character: players[0], room:, params: parameters.merge(team_count: 1, enemy_count: 1))
    expect(normalized).to be_success
    expect(normalized.application.enemy_count).to eq(2)
  end
  it "enforces alignment sides and closed capacity" do
    players[0].update!(alignment: "light")
    players[1].update!(alignment: "light")
    players[2].update!(alignment: "dark")
    players[3].update!(alignment: "chaos")
    app = handler.create(character: players[0], room:, params: parameters.merge(fight_kind: "alignment_vs_alignment")).application
    expect(assembly.join(application: app, character: players[2], team: "a")).not_to be_success
    expect(assembly.join(application: app, character: players[1], team: "a")).to be_success
    expect(assembly.join(application: app, character: players[2], team: "b")).to be_success
    expect(assembly.join(application: app, character: players[3], team: "b")).not_to be_success
    assembly.withdraw(application: app, character: players[0])
    expect(handler.create(character: players[0], room:, params: parameters.merge(fight_kind: "closed", enemy_count: 11))).not_to be_success
    app = handler.create(character: players[0], room:, params: parameters.merge(fight_kind: "alignment_vs_all")).application
    expect(assembly.join(application: app, character: players[4], team: "b")).to be_success
  end
end
