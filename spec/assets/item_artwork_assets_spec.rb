# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Item artwork assets" do
  it "covers all starter goods and every license tier explicitly" do
    keys = JSON.parse(File.read(Rails.root.join("db/seeds/data/starter_shop.json"))).map { |item| item.fetch("key") }
    keys += %w[trading_license_i trading_license_ii trading_license_iii doctor_license_i doctor_license_ii doctor_license_iii]
    expect(InventoriesHelper::ITEM_ARTWORK_PATHS.keys).to match_array(keys)
  end

  it "ships a readable original bitmap for every mapped item" do
    InventoriesHelper::ITEM_ARTWORK_PATHS.each_value do |asset|
      path = Rails.root.join("app/assets/images", asset)
      expect(path).to exist

      header = File.binread(path, 24)
      expect(header.byteslice(0, 8)).to eq("\x89PNG\r\n\x1A\n".b)
      expect(header.byteslice(12, 4)).to eq("IHDR")
      expect(header.byteslice(16, 8).unpack("N2")).to all(be >= 60)
    end
  end
end
