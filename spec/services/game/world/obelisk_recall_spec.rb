# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::ObeliskRecall do
  let(:city) { create(:zone, name: "Obelisk City", location_type: "city") }
  let(:shore) { create(:zone, name: "Obelisk Shore", location_type: "outdoor", width: 20, height: 20) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone: shore, x: 4, y: 5) }

  before do
    character.user.currency_wallet.update!(nv_balance: 40)
  end

  it "binds and recalls for NV" do
    bind = described_class.new(character:, action: "bind").call
    expect(bind.success).to be(true)

    position.update!(zone: city, x: 0, y: 0)
    recall = described_class.new(character:, action: "recall").call

    expect(recall.success).to be(true)
    expect(character.position.reload).to have_attributes(zone_id: shore.id, x: 4, y: 5)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(25)
  end

  it "rejects recall without a bind" do
    expect(described_class.new(character:, action: "recall").call.success).to be(false)
  end
end
