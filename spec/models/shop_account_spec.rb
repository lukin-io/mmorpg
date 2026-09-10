# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShopAccount, type: :model do
  let(:shop) { create(:city_hotspot, :shop) }

  it "persists an explicitly authored two-decimal NV balance" do
    account = described_class.create!(location: shop, nv_balance: "99977307.40")

    expect(account.reload.nv_balance).to eq(BigDecimal("99977307.40"))
    expect(described_class.columns_hash.fetch("nv_balance").type).to eq(:decimal)
    expect(account.location).to eq(shop)
  end

  it "keeps city and village Shop balances independent" do
    city_account = described_class.create!(location: shop, nv_balance: "7.00")
    village_account = described_class.create!(location: create(:tile_building, :world_location), nv_balance: "3.50")

    city_account.update!(nv_balance: "14.00")

    expect(village_account.reload.nv_balance).to eq(BigDecimal("3.50"))
    expect(village_account.location).to be_a(TileBuilding)
  end

  it "accepts zero and the precision boundary without inventing a default balance" do
    account = described_class.new(location: shop)
    expect(account.nv_balance).to be_nil
    expect(account).not_to be_valid

    ["0.00", "9999999999.99"].each do |amount|
      account.nv_balance = amount
      expect(account).to be_valid
    end
  end

  it "rejects missing, negative, nonfinite, and out-of-range balances" do
    account = described_class.new(location: shop)

    [nil, "-0.01", "10000000000.00", BigDecimal("NaN"), BigDecimal("Infinity")].each do |amount|
      account.nv_balance = amount
      expect(account).not_to be_valid
      expect(account.errors[:nv_balance]).to be_present
    end
  end

  it "accepts a temporarily inactive authored Shop without changing its funds" do
    shop.update!(active: false)

    expect(described_class.new(location: shop, nv_balance: 0)).to be_valid
  end

  it "rejects non-Shop or unsupported locations" do
    [create(:city_hotspot, :arena), create(:tile_building), create(:user), nil].each do |location|
      expect(described_class.new(location:, nv_balance: 0)).not_to be_valid
    end
  end

  it "rejects missing polymorphic records" do
    account = described_class.new(location_type: "CityHotspot", location_id: -1, nv_balance: 0)

    expect(account).not_to be_valid
    expect(account.errors[:location]).to be_present
  end

  it "allows only one account per exact Shop at validation and database boundaries" do
    described_class.create!(location: shop, nv_balance: 0)
    duplicate = described_class.new(location: shop, nv_balance: 0)
    expect(duplicate).not_to be_valid

    expect do
      described_class.transaction(requires_new: true) { duplicate.save!(validate: false) }
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces non-null and nonnegative finite funds when validations are bypassed" do
    account = described_class.create!(location: shop, nv_balance: 0)

    [nil, "-0.01", "NaN"].each do |amount|
      expect do
        described_class.transaction(requires_new: true) { account.update_columns(nv_balance: amount) }
      end.to raise_error(ActiveRecord::StatementInvalid)
      expect(account.reload.nv_balance).to eq(0)
    end
  end

  it "enforces supported location types at the database boundary" do
    account = described_class.create!(location: shop, nv_balance: 0)

    expect do
      described_class.transaction(requires_new: true) { account.update_columns(location_type: "User") }
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
