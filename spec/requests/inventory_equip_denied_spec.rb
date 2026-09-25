# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory equip denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Equip Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when equipping a missing inventory row" do
    post equip_inventory_path, params: {item_id: 999_999_999}

    expect(response).to redirect_to(inventory_path(item_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-inventory-item-denied="1"')
    expect(response.body).to include('data-inventory-recovery="world"')
  end

  it "recovers when unequipping an empty slot" do
    post unequip_inventory_path, params: {slot: "head"}

    expect(response).to redirect_to(inventory_path(equip_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-inventory-equip-denied="1"')
    expect(response.body).to include('data-inventory-recovery="world"')
  end
end
