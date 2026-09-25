# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::ResourceExchange do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:wallet) { user.currency_wallet || user.create_currency_wallet!(nv_balance: 500) }

  before do
    wallet.update!(nv_balance: 500)
    Game::Professions::Templates.ensure_craft_items!
    character.inventory || character.create_inventory!
  end

  def grant!(key, qty = 1)
    inventory = character.inventory || character.create_inventory!
    template = ItemTemplate.find_by!(key:)
    Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: qty)
  end

  describe "#call sell" do
    it "pays government price for coal and removes the stack" do
      grant!("coal_chunk", 2)
      result = described_class.new(character:, item_key: "coal_chunk", quantity: 2, mode: :sell).call

      expect(result.success).to be(true)
      expect(result.paid).to eq(Game::World::ResourceExchange.sell_price("coal_chunk") * 2)
      expect(wallet.reload.nv_balance.to_i).to eq(500 + result.paid)
      expect(character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "coal_chunk"}).sum(:quantity)).to eq(0)
    end

    it "rejects unknown resources without mutating wallet" do
      before = wallet.nv_balance
      result = described_class.new(character:, item_key: "not_a_resource", mode: :sell).call

      expect(result.success).to be(false)
      expect(wallet.reload.nv_balance).to eq(before)
    end

    it "rejects when bag lacks quantity" do
      grant!("iron_ore", 1)
      result = described_class.new(character:, item_key: "iron_ore", quantity: 3, mode: :sell).call

      expect(result.success).to be(false)
      expect(result.message).to eq(I18n.t("game.locations.exchange_not_enough"))
    end
  end

  describe "#call buy" do
    it "charges markup and grants the item" do
      result = described_class.new(character:, item_key: "iron_ore", quantity: 1, mode: :buy).call

      expect(result.success).to be(true), -> { result.message }
      expect(result.spent).to eq(28) # 25 * 1.1 ceil
      expect(wallet.reload.nv_balance.to_i).to eq(472)
      expect(character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "iron_ore"}).sum(:quantity)).to eq(1)
    end

    it "fails closed on short NV" do
      wallet.update!(nv_balance: 5)
      result = described_class.new(character:, item_key: "silver_ore", mode: :buy).call

      expect(result.success).to be(false)
      expect(result.message).to eq(I18n.t("game.shop.not_enough_nv"))
    end
  end

  describe "#call deposit/withdraw" do
    it "stores and returns resources under the cap" do
      grant!("ash_herb", 2)
      deposit = described_class.new(character:, item_key: "ash_herb", quantity: 2, mode: :deposit).call
      expect(deposit.success).to be(true)
      expect(described_class.storage_for(character.reload)["ash_herb"]).to eq(2)

      withdraw = described_class.new(character:, item_key: "ash_herb", quantity: 1, mode: :withdraw).call
      expect(withdraw.success).to be(true)
      expect(described_class.storage_for(character.reload)["ash_herb"]).to eq(1)
    end
  end

  describe ".gov_price" do
    it "matches Neverlands wiki government rows for coal and iron" do
      expect(described_class.gov_price("coal_chunk")).to eq(20)
      expect(described_class.gov_price("iron_ore")).to eq(25)
      expect(described_class.gov_price("silver_ore")).to eq(30)
    end
  end
end
