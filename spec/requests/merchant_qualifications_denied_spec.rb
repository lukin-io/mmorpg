# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Merchant qualification denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Merchant Deny City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when merchant accept is not available" do
    post accept_merchant_qualification_path

    expect(response).to redirect_to(world_path(merchant_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-merchant-denied="1"')
    expect(response.body).to include('data-merchant-recovery="world"')
  end
end
