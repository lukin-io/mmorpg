# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Combat routing", type: :routing do
  describe "combat routes" do
    it "routes GET /combat to combat#show" do
      expect(get: "/combat").to route_to("combat#show")
    end

    it "routes POST /combat/action to combat#action" do
      expect(post: "/combat/action").to route_to("combat#action")
    end

    it "routes POST /combat/start to combat#start" do
      expect(post: "/combat/start").to route_to("combat#start")
    end

    it "routes POST /combat/flee to combat#flee" do
      expect(post: "/combat/flee").to route_to("combat#flee")
    end

    it "routes GET /combat/skills to combat#skills" do
      expect(get: "/combat/skills").to route_to("combat#skills")
    end
  end

  describe "arena routes" do
    it "routes GET /arena to arena#index" do
      expect(get: "/arena").to route_to("arena#index")
    end

    it "routes GET /arena/lobby to arena#lobby" do
      expect(get: "/arena/lobby").to route_to("arena#lobby")
    end
  end

  describe "arena rooms routes" do
    it "routes GET /arena_rooms to arena_rooms#index" do
      expect(get: "/arena_rooms").to route_to("arena_rooms#index")
    end

    it "routes GET /arena_rooms/:id to arena_rooms#show" do
      expect(get: "/arena_rooms/1").to route_to("arena_rooms#show", id: "1")
    end
  end

  describe "tactical arena routes" do
    it "routes GET /tactical_arena to tactical_arena#index" do
      expect(get: "/tactical_arena").to route_to("tactical_arena#index")
    end

    it "routes GET /tactical_arena/:id to tactical_arena#show" do
      expect(get: "/tactical_arena/1").to route_to("tactical_arena#show", id: "1")
    end

    it "routes POST /tactical_arena/:id/move to tactical_arena#move" do
      expect(post: "/tactical_arena/1/move").to route_to("tactical_arena#move", id: "1")
    end

    it "routes POST /tactical_arena/:id/attack to tactical_arena#attack" do
      expect(post: "/tactical_arena/1/attack").to route_to("tactical_arena#attack", id: "1")
    end
  end

  describe "world routes" do
    it "routes GET /world to world#show" do
      expect(get: "/world").to route_to("world#show")
    end

    it "routes POST /world/move to world#move" do
      expect(post: "/world/move").to route_to("world#move")
    end

    it "routes POST /world/dialogue_action to world#dialogue_action" do
      expect(post: "/world/dialogue_action").to route_to("world#dialogue_action")
    end
  end
end
