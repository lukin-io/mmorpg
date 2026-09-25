# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory items", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Inventory Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when discarding a missing inventory row" do
    delete inventory_item_path(999_999_999)

    expect(response).to redirect_to(inventory_path(item_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-inventory-item-denied="1"')
    expect(response.body).to include('data-inventory-recovery="world"')
  end
end
