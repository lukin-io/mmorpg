# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Allocation denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Alloc Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when saving empty primary-stat allocations" do
    patch stats_character_path(character), params: {allocated_stats: {}}

    expect(response).to redirect_to(stats_character_path(character, allocation_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-allocation-denied="1"')
    expect(response.body).to include('data-allocation-recovery="world"')
    expect(response.body).to include('data-allocation-recovery="sheet"')
  end
end
