# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena matches denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:zone) { create(:zone, name: "Arena Match Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when opening a missing arena match" do
    get arena_match_path(999_999_999)

    expect(response).to redirect_to(arena_index_path(arena_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-arena-denied="1"')
    expect(response.body).to include('data-arena-recovery="city"').or include('data-arena-recovery="duels"')
  end
end
