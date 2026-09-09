# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World cell-art assets" do
  def png_dimensions(path)
    header = File.binread(path, 24)

    expect(header.byteslice(0, 8)).to eq("\x89PNG\r\n\x1A\n".b)
    expect(header.byteslice(12, 4)).to eq("IHDR")
    header.byteslice(16, 8).unpack("N2")
  end

  before { Game::World::CellArtCatalog.reload! }

  it "matches every source-backed catalog definition to a project-owned bitmap" do
    config = Game::World::CellArtCatalog.config

    expect(config).not_to be_empty

    config.each_value do |definition|
      asset = definition.fetch("asset")
      columns = definition.fetch("columns")
      rows = definition.fetch("rows")
      path = Rails.root.join("app/assets/images", asset)

      expect(asset).to start_with("world/")
      expect(path).to exist
      expect(definition).to include(
        "cell_width" => 100,
        "cell_height" => 100,
        "source_reference" => a_string_matching(/neverlands/)
      )
      expect(columns).to be_positive
      expect(rows).to be_positive

      expect(png_dimensions(path)).to eq([columns * 100, rows * 100])
    end
  end

  it "retains the legacy pond sheet for independently authored references" do
    pond = Game::World::CellArtCatalog.config.fetch("forpost_pond")

    expect(pond).to include("asset" => "world/forpost-pond-landscape.png", "columns" => 5, "rows" => 5)
    expect(png_dimensions(Rails.root.join("app/assets/images", pond.fetch("asset")))).to eq([500, 500])
    presentations = (0..4).flat_map do |row|
      (0..4).map { |column| Game::World::CellArtCatalog.resolve("key" => "forpost_pond", "column" => column, "row" => row) }
    end
    expect(presentations.map(&:asset).uniq).to eq([pond.fetch("asset")])
    expect(presentations.map { |art| [art.background_x, art.background_y] }.uniq.size).to eq(25)
    expect(Game::World::CellArtCatalog.resolve("key" => "forpost_pond", "column" => 5, "row" => 0)).to be_nil
  end

  it "ships a complete 21-by-13 starter landscape and exactly one 100px PNG per logical cell" do
    starter = Game::World::CellArtCatalog.config.fetch("forpost_starter")
    directory = Rails.root.join("app/assets/images", starter.fetch("slices_directory"))
    expect(starter).to include("columns" => 21, "rows" => 13, "landmarks_in_art" => true)
    expect(png_dimensions(Rails.root.join("app/assets/images", starter.fetch("asset")))).to eq([2100, 1300])
    expected_files = (0...13).flat_map { |row| (0...21).map { |column| "#{column}_#{row}.png" } }
    expect(directory.glob("*.png").map { |path| path.basename.to_s }).to match_array(expected_files)

    expected_files.each do |filename|
      expect(png_dimensions(directory.join(filename))).to eq([100, 100])
      column, row = filename.delete_suffix(".png").split("_").map(&:to_i)
      presentation = Game::World::CellArtCatalog.resolve("key" => "forpost_starter", "column" => column, "row" => row)
      expect(presentation).to have_attributes(
        asset: "#{starter.fetch('slices_directory')}/#{filename}", physical_slice: true,
        sheet_width: 100, sheet_height: 100, background_x: 0, background_y: 0
      )
    end
  end
end
