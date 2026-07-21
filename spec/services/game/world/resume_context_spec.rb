# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::ResumeContext do
  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city, name: "Resume City") }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:shop_hotspot) { create(:city_hotspot, :shop, zone: city, required_level: 1) }

  subject(:resume_context) { described_class.new(character:) }

  it "defaults to the persisted world or city position" do
    expect(resume_context.resume_path).to eq("/world")
  end

  it "remembers and resolves an accessible shop with sanitized exact state" do
    resume_context.remember_shop!(
      params: {
        mode: "sell",
        category: "jewelry",
        min_price: "10",
        max_price: "90",
        injected: "ignored"
      }
    )

    expect(resume_context.resume_path).to eq(
      "/shop?category=jewelry&max_price=90&min_price=10&mode=sell"
    )
  end

  it "normalizes unsupported and negative shop params" do
    resume_context.remember_shop!(
      params: {mode: "admin", category: "everything", min_price: "-1"}
    )

    expect(character.reload.gameplay_context).to eq(
      "name" => "shop",
      "params" => {"mode" => "buy", "category" => "all"}
    )
  end

  it "keeps zero-value filter boundaries and drops null or non-numeric filters" do
    resume_context.remember_shop!(
      params: {
        min_level: "0",
        max_level: nil,
        min_price: "not-a-number",
        max_price: 0
      }
    )

    expect(character.reload.gameplay_context).to eq(
      "name" => "shop",
      "params" => {
        "mode" => "buy",
        "category" => "all",
        "min_level" => "0",
        "max_price" => "0"
      }
    )
  end

  it "falls back to the persisted world position when shop access is stale" do
    resume_context.remember_shop!
    shop_hotspot.update!(active: false)

    expect(resume_context.resume_path).to eq("/world")
  end

  it "falls back when the character moved outside or no longer meets the level requirement" do
    resume_context.remember_shop!

    position.update!(zone: create(:zone, :mvp_outdoor_region), x: 7, y: 9)
    expect(resume_context.resume_path).to eq("/world")

    position.update!(zone: city, x: 5, y: 5)
    shop_hotspot.update!(required_level: character.level + 1)
    expect(resume_context.resume_path).to eq("/world")
  end

  it "resets a shop context when the world or city surface is visited" do
    resume_context.remember_shop!

    resume_context.remember_world!

    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    expect(resume_context.resume_path).to eq("/world")
  end

  it "remembers and resumes a documented city building from its parent node" do
    create(:city_hotspot, :read_only_city_building, zone: city)

    resume_context.remember_city_building!(building_key: "market")

    expect(character.reload.gameplay_context).to eq(
      "name" => "city_building",
      "params" => {"building_key" => "market"}
    )
    expect(resume_context.resume_path).to eq("/city/buildings/market")
  end

  it "rejects unsupported building persistence and falls back after leaving its parent node" do
    create(:city_hotspot, :read_only_city_building, zone: city)

    expect {
      resume_context.remember_city_building!(building_key: nil)
    }.to raise_error(ArgumentError, "Unsupported city building")

    resume_context.remember_city_building!(building_key: "market")
    position.update!(zone: create(:zone, :mvp_outdoor_region), x: 7, y: 0)

    expect(resume_context.resume_path).to eq("/world")
  end
end
