# frozen_string_literal: true

require "rails_helper"

RSpec.describe Character, type: :model do
  describe "persisted gameplay context" do
    let(:character) { create(:character, metadata: {"valor" => 12}) }

    it "defaults missing, null, and malformed context to the world" do
      expect(character.gameplay_context).to eq("name" => "world", "params" => {})

      null_context = build(:character, :with_null_gameplay_context)
      expect(null_context.gameplay_context).to eq("name" => "world", "params" => {})

      malformed = build(:character, :with_malformed_gameplay_context)
      expect(malformed.gameplay_context).to eq("name" => "world", "params" => {})

      malformed_shop = build(:character, :with_malformed_shop_gameplay_context)
      expect(malformed_shop.gameplay_context).to eq("name" => "world", "params" => {})
    end

    it "remembers an allowlisted shop context without replacing unrelated metadata" do
      character.remember_gameplay_context!(
        name: :shop,
        params: {mode: "sell", category: "jewelry"}
      )

      expect(character.reload.gameplay_context).to eq(
        "name" => "shop",
        "params" => {"mode" => "sell", "category" => "jewelry"}
      )
      expect(character.metadata["valor"]).to eq(12)
    end

    it "accepts an allowlisted city-building context" do
      character.remember_gameplay_context!(
        name: :city_building,
        params: {building_key: "market"}
      )

      expect(character.reload.gameplay_context).to eq(
        "name" => "city_building",
        "params" => {"building_key" => "market"}
      )
    end

    it "rejects arbitrary paths and non-object params" do
      expect {
        character.remember_gameplay_context!(name: "https://example.invalid")
      }.to raise_error(ArgumentError, "Unsupported gameplay context")

      expect {
        character.remember_gameplay_context!(name: "shop", params: nil)
      }.to raise_error(ArgumentError, "Gameplay context params must be an object")

      expect {
        character.remember_gameplay_context!(name: nil)
      }.to raise_error(ArgumentError, "Unsupported gameplay context")
    end
  end
end
