# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authored Arena hall access" do
  it "seeds ten source halls idempotently, including level-zero Help and current Patrons gate" do
    load Rails.root.join("db/seeds/arena_rooms.rb")
    expect(ArenaRoom.count).to eq(10)
    expect(ArenaRoom.find_by!(slug: "help")).to have_attributes(level_min: 0, level_max: 5)
    expect(ArenaRoom.find_by!(slug: "patron").level_min).to eq(16)
    expect(ArenaRoom.find_by!(slug: "dark").alignment_restriction).to eq("dark")
    expect { load Rails.root.join("db/seeds/arena_rooms.rb") }.not_to change(ArenaRoom, :count)
    Game::World::ArenaNpcConfig.reload!
    expect(Game::World::ArenaNpcConfig.for_room("help").map { |entry| entry[:key] }).to include("arena_training_dummy")
    expect(Game::World::ArenaNpcConfig.for_room("dark")).to be_empty
  end
end
