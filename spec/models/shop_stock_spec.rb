# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShopStock, type: :model do
  let(:account) { ShopAccount.create!(location: create(:city_hotspot, :shop), nv_balance: 0) }
  let(:template) { create(:item_template) }

  def stock_attributes
    {shop_account: account, item_template: template, current: 1, maximum: 500}
  end

  it "persists exact stock separately for each Shop" do
    city_stock = described_class.create!(**stock_attributes)
    village_account = ShopAccount.create!(location: create(:tile_building, :world_location), nv_balance: 0)
    village_stock = described_class.create!(**stock_attributes, shop_account: village_account, current: 3)

    city_stock.update!(current: 0)

    expect(city_stock.reload).to be_out_of_stock
    expect(village_stock.reload.current).to eq(3)
    expect(account.shop_stocks).to contain_exactly(city_stock)
  end

  it "distinguishes available, empty, and full stock at exact capacity boundaries" do
    stock = described_class.new(**stock_attributes)
    expect(stock).not_to be_out_of_stock
    expect(stock).not_to be_full
    expect(stock).to be_accepts_return

    stock.current = 0
    expect(stock).to be_out_of_stock
    expect(stock).to be_accepts_return

    stock.current = 500
    expect(stock).to be_full
    expect(stock).not_to be_accepts_return
  end

  it "retains an observed quantity without inventing an unknown maximum or sale capacity" do
    stock = described_class.create!(**stock_attributes, current: 666, maximum: nil)

    expect(stock.reload.current).to eq(666)
    expect(stock.maximum).to be_nil
    expect(stock).not_to be_out_of_stock
    expect(stock).not_to be_full
    expect(stock).not_to be_accepts_return
  end

  it "supports an explicitly closed zero-capacity stock" do
    stock = described_class.create!(**stock_attributes, current: 0, maximum: 0)

    expect(stock).to be_out_of_stock
    expect(stock).to be_full
    expect(stock).not_to be_accepts_return
  end

  it "rejects omitted, negative, fractional, nonnumeric, and infinite quantities" do
    [nil, -1, 1.5, "bad", "Infinity"].each do |quantity|
      stock = described_class.new(**stock_attributes, current: quantity)
      expect(stock).not_to be_valid
      expect(stock.errors[:current]).to be_present
    end
  end

  it "rejects negative, fractional, and invalid maxima or counts exceeding capacity" do
    [-1, 1.5, "bad", "Infinity"].each do |maximum|
      expect(described_class.new(**stock_attributes, maximum:)).not_to be_valid
    end
    expect(described_class.new(**stock_attributes, current: 501)).not_to be_valid
  end

  it "rejects missing Shop and item associations" do
    expect(described_class.new(**stock_attributes, shop_account: nil)).not_to be_valid
    expect(described_class.new(**stock_attributes, item_template: nil)).not_to be_valid
  end

  it "enforces one stock row per item at each Shop in validations and the database" do
    described_class.create!(**stock_attributes)
    duplicate = described_class.new(**stock_attributes)
    expect(duplicate).not_to be_valid

    expect do
      described_class.transaction(requires_new: true) { duplicate.save!(validate: false) }
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces quantity and capacity boundaries when validations are bypassed" do
    stock = described_class.create!(**stock_attributes)

    [{current: nil}, {current: -1}, {maximum: -1}, {current: 501}].each do |attributes|
      expect do
        described_class.transaction(requires_new: true) { stock.update_columns(attributes) }
      end.to raise_error(ActiveRecord::StatementInvalid)
      expect(stock.reload.current).to eq(1)
      expect(stock.maximum).to eq(500)
    end
  end

  it "enforces Shop and item foreign keys" do
    stock = described_class.create!(**stock_attributes)

    [{shop_account_id: -1}, {item_template_id: -1}].each do |attributes|
      expect do
        described_class.transaction(requires_new: true) { stock.update_columns(attributes) }
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  it "prevents accidental deletion of an account containing stock" do
    described_class.create!(**stock_attributes)

    expect { account.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
