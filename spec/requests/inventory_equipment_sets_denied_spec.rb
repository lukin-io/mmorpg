# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory equipment sets denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Set Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when wearing a missing equipment set" do
    post wear_equipment_set_inventory_path, params: {set_name: "__missing_ashen_set__"}

    expect(response).to redirect_to(inventory_path(set_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-inventory-set-denied="1"')
    expect(response.body).to include('data-inventory-recovery="world"').or include('data-inventory-recovery="shop"')
  end
end
