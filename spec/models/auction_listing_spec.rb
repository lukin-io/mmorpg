# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuctionListing do
  let(:seller) { create(:character) }

  it "allows crafted rare gear and rejects ordinary items" do
    crafted = create(:item_template, key: "ash_ranger_test")
    ordinary = create(:item_template, key: "ordinary_sword")

    expect(described_class.new(seller_character: seller, item_template: crafted, quantity: 1, price_nv: 10, status: "open")).to be_valid
    expect(described_class.new(seller_character: seller, item_template: ordinary, quantity: 1, price_nv: 10, status: "open")).not_to be_valid
  end

  it "allows rare crafting materials" do
    material = create(:item_template, :material, key: "ash_wolf_pelt")

    listing = described_class.new(seller_character: seller, item_template: material, quantity: 1, price_nv: 10, status: "open")

    expect(listing).to be_valid
  end

  it "queries the craft-goods board without widening the allowlist" do
    crafted = create(:item_template, key: "ash_battle_test")
    material = create(:item_template, :material, key: "mist_spider_silk")
    [crafted, material].each do |template|
      described_class.create!(
        seller_character: seller, item_template: template,
        quantity: 1, price_nv: 10, status: "open"
      )
    end

    expect(described_class.open.craft_goods.pluck(:item_template_id)).to contain_exactly(crafted.id, material.id)
  end
end
