# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory transfer denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let!(:position) { create(:character_position, character:) }

  before do
    user.create_currency_wallet!(nv_balance: 10) unless user.currency_wallet
    sign_in user, scope: :user
  end

  it "recovers when NV transfer targets a missing character" do
    post transfer_money_inventory_path, params: {recipient_name: "__missing_ashen_player__", amount: 1}

    expect(response).to redirect_to(inventory_path(transfer_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-inventory-transfer-denied="1"')
    expect(response.body).to include('data-inventory-recovery="world"')
  end
end
