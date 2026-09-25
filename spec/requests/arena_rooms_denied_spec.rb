# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena rooms denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Arena Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when opening a missing arena room" do
    get arena_room_path(999_999_999)

    expect(response).to redirect_to(arena_index_path(arena_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-arena-denied="1"')
    expect(response.body).to include('data-arena-recovery="city"')
  end
end
