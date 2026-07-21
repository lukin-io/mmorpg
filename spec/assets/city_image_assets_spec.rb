# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Retained city image assets" do
  it "keeps the existing city, arena, and gate images in the repository" do
    asset_paths = %w[city.png arena.png gate.png].map do |filename|
      Rails.root.join("app/assets/images", filename)
    end

    expect(asset_paths).to all(exist)
  end


  it "keeps the project-owned Forpost wilderness texture used by 100px cells" do
    terrain = Rails.root.join("app/assets/images/world/forpost-terrain.png")

    expect(terrain).to exist
    expect(File.size(terrain)).to be > 10_000
  end
end
