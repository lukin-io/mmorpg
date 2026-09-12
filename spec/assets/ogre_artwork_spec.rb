# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ogre artwork delivery" do
  def dimensions(asset)
    File.binread(Rails.root.join("app/assets/images", asset), 24).byteslice(16, 8).unpack("N2")
  end

  it "keeps the complete portrait at the exact six-times paper-doll dimensions" do
    expect(dimensions("npc/ogre.png")).to eq([690, 1530])
  end

  it "delivers every captured equipment category in its slot aspect ratio" do
    {helmet: [1, 1], amulet: [2, 1], club: [2, 3], boots: [1, 1], ring: [1, 1],
     bracers: [3, 2], gloves: [3, 2], armor: [2, 3], belt: [2, 1]}.each do |category, ratio|
      width, height = dimensions("npc/equipment/ogre_#{category}.png")
      expect(width * ratio.last).to eq(height * ratio.first)
    end
  end

  it "resolves the paired habitat to individual base and density slices at unchanged logical size" do
    expect(dimensions("world/forpost-ogre-habitat.png")).to eq([100, 200])
    2.times do |row|
      art = Game::World::CellArtCatalog.resolve("key" => "forpost_ogre_habitat", "column" => 0, "row" => row)
      expect(art).to have_attributes(cell_width: 100, cell_height: 100, physical_slice: true,
        background_x: 0, background_y: 0, landmarks_in_art: false)
      expect(dimensions(art.asset)).to eq([100, 100])
      expect(dimensions(art.high_density_asset)).to eq([200, 200])
    end
    expect(Game::World::CellArtCatalog.resolve("key" => "forpost_ogre_habitat", "row" => 2)).to be_nil
  end
end
