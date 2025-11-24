require "rails_helper"

RSpec.describe Economy::MedicalSupplySink do
  let(:character) { create(:character, :with_position) }
  let(:zone) { character.position.zone }
  let(:user) { character.user }
  let!(:pool) { MedicalSupplyPool.create!(zone:, item_name: "Field Bandage", available_quantity: 5) }

  it "charges the character and consumes supplies" do
    user.currency_wallet.update!(gold_balance: 500, silver_balance: 500)

    described_class.new(zone: zone).consume!(character: character)

    wallet = user.currency_wallet.reload
    expect(wallet.gold_balance).to eq(500 - Economy::MedicalSupplySink::GOLD_FEE)
    expect(wallet.silver_balance).to eq(500 - Economy::MedicalSupplySink::SILVER_FEE)
    expect(pool.reload.available_quantity).to eq(4)
  end
end
