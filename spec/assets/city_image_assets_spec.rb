# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Retained city image assets" do
  it "keeps the current Central Square, arena, and gate images in the repository" do
    asset_paths = %w[city/central-square.png arena.png gate.png].map do |filename|
      Rails.root.join("app/assets/images", filename)
    end

    expect(asset_paths).to all(exist)
  end

  it "ships the original route arrow as a 256px PNG with alpha" do
    arrow = Rails.root.join("app/assets/images/city/route-arrow.png")
    expect(arrow).to exist

    header = File.binread(arrow, 26)
    expect(header.byteslice(0, 8)).to eq("\x89PNG\r\n\x1A\n".b)
    expect(header.byteslice(12, 4)).to eq("IHDR")
    expect(header.byteslice(16, 8).unpack("N2")).to eq([256, 256])
    expect(header.getbyte(25)).to eq(6)
  end

  it "keeps the project-owned Forpost wilderness texture used by 100px cells" do
    terrain = Rails.root.join("app/assets/images/world/forpost-terrain.png")

    expect(terrain).to exist
    expect(File.size(terrain)).to be > 10_000
  end
end
