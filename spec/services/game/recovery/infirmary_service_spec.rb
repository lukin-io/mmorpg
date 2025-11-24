require "rails_helper"

RSpec.describe Game::Recovery::InfirmaryService do
  let(:zone) { create(:zone, metadata: {"infirmary" => {"reduction_seconds" => 30}}) }
  let(:character) { create(:character, :with_position) }
  let(:position) { character.position.tap { |pos| pos.update!(zone:, respawn_available_at: 2.minutes.from_now) } }
  let!(:pool) { MedicalSupplyPool.create!(zone:, item_name: "Field Bandage", available_quantity: 5) }

  before do
    character.user.currency_wallet.update!(gold_balance: 200, silver_balance: 200)
  end

  it "reduces the respawn timer when an infirmary is configured" do
    service = described_class.new(zone:)

    expect(service.available?).to be_truthy

    service.stabilize!(character_position: position)

    expect(position.reload.respawn_available_at).to be < 2.minutes.from_now
    expect(character.user.currency_wallet.reload.gold_balance).to be < 200
    expect(pool.reload.available_quantity).to eq(4)
  end
end
