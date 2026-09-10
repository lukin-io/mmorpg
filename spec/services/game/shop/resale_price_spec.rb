# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::ResalePrice do
  it "matches the healthy penknife and damaged dagger live quotes" do
    expect(described_class.new(base_price: 7, current_durability: 10, max_durability: 10).amount).to eq(BigDecimal("1.40"))
    expect(described_class.new(base_price: 400, current_durability: 84, max_durability: 100).amount).to eq(BigDecimal("67.20"))
    expect(described_class.new(base_price: 18, current_durability: 29, max_durability: 30).amount).to eq(BigDecimal("3.48"))
  end

  it "changes rates at each published merchant proficiency boundary" do
    {0 => 20, 99 => 20, 100 => 30, 224 => 30, 225 => 40, 349 => 40,
     350 => 50, 474 => 50, 475 => 60, 599 => 60, 600 => 70, 1_000 => 70}.each do |skill, percent|
      quote = described_class.new(base_price: 100, trading_skill: skill)
      expect(quote.percent).to eq(percent)
      expect(quote.amount).to eq(percent)
    end
  end

  it "rounds the final decimal payout once without a minimum payment" do
    expect(described_class.new(base_price: "0.03", current_durability: 1, max_durability: 2).amount).to eq(0)
    expect(described_class.new(base_price: 4, current_durability: 15, max_durability: 30).amount).to eq(BigDecimal("0.40"))
  end

  it "does not quote a payout for valueless, broken or inconsistent items" do
    expect(described_class.new(base_price: 0).amount).to eq(0)
    expect(described_class.new(base_price: -7).amount).to eq(0)
    expect(described_class.new(base_price: 7, current_durability: 0, max_durability: 10).amount).to eq(0)
    expect(described_class.new(base_price: 7, current_durability: 11, max_durability: 10).amount).to eq(0)
    expect(described_class.new(base_price: 7, max_durability: 10).amount).to eq(0)
  end
end
