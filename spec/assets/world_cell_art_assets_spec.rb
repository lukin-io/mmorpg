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
end
