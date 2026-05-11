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
    it "does not route the removed legacy arena rooms index" do
      expect(get: "/arena_rooms").not_to be_routable
    end

    it "routes GET /arena_rooms/:id to arena_rooms#show" do
      expect(get: "/arena_rooms/1").to route_to("arena_rooms#show", id: "1")
    end

    # Bug fix regression: JavaScript was using /arena/rooms/:id instead of /arena_rooms/:id
    it "does NOT route /arena/rooms/:id (incorrect path)" do
      expect(get: "/arena/rooms/1").not_to be_routable
    end
  end

  describe "arena applications routes" do
    it "routes POST /arena_applications/:id/accept to arena_applications#accept" do
      expect(post: "/arena_applications/1/accept").to route_to("arena_applications#accept", id: "1")
    end

    it "routes DELETE /arena_applications/:id/cancel to arena_applications#cancel" do
      expect(delete: "/arena_applications/1/cancel").to route_to("arena_applications#cancel", id: "1")
    end

    # Bug fix regression: JavaScript was using /arena/applications/:id/accept
    it "does NOT route /arena/applications/:id/accept (incorrect path)" do
      expect(post: "/arena/applications/1/accept").not_to be_routable
    end

    it "does NOT route DELETE /arena/applications/:id (incorrect path)" do
      expect(delete: "/arena/applications/1").not_to be_routable
    end
  end

  describe "arena matches routes" do
    it "does not route the removed legacy arena match queue index" do
      expect(get: "/arena_matches").not_to be_routable
    end

    it "does not route the removed legacy arena match queue create endpoint" do
      expect(post: "/arena_matches").not_to be_routable
    end

    it "routes GET /arena_matches/:id to arena_matches#show" do
      expect(get: "/arena_matches/1").to route_to("arena_matches#show", id: "1")
    end

    # Bug fix regression: JavaScript was using /arena/matches/:id
    it "does NOT route /arena/matches/:id (incorrect path)" do
      expect(get: "/arena/matches/1").not_to be_routable
    end
  end

  describe "tactical arena routes" do
    it "does not route the removed legacy tactical arena lobby" do
      expect(get: "/tactical_arena").not_to be_routable
    end

    it "does not route removed legacy tactical arena matches" do
      expect(get: "/tactical_arena/1").not_to be_routable
    end

    it "does not route removed legacy tactical movement" do
      expect(post: "/tactical_arena/1/move").not_to be_routable
    end

    it "does not route removed legacy tactical attacks" do
      expect(post: "/tactical_arena/1/attack").not_to be_routable
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
