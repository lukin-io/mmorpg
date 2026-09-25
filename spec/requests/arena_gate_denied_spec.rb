# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena gate denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:city) { create(:zone, :city_node, name: "Gate Deny Square") }
  let(:character) { create(:character, user:, level: 10) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:arena) { create(:city_hotspot, :arena, zone: city) }

  before { sign_in user, scope: :user }

  it "recovers when the Arena lobby is opened without the city hotspot entry" do
    get arena_index_path

    expect(response).to redirect_to(world_path(arena_gate_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-arena-gate-denied="1"')
    expect(response.body).to include('data-arena-recovery="world"')
  end
end
