# frozen_string_literal: true

require "rails_helper"

RSpec.describe GameOverview::SectionCatalog do
  describe "#section" do
    it "returns deep-symbolized content for each configured section" do
      catalog = described_class.new

      vision = catalog.section(:vision_objectives)

      expect(vision.key).to eq(:vision_objectives)
      expect(vision.content[:title]).to eq("Vision & Objectives")
      expect(vision.content[:bullets]).to be_present
    end
  end

  describe "#hero" do
    it "exposes hero copy from config" do
      hero = described_class.new.hero

      expect(hero[:title]).to include("Game Overview")
      expect(hero[:ctas]).to be_an(Array)
    end
  end
end
