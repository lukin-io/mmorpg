# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CombatReturnContext do
  include Rails.application.routes.url_helpers

  let(:character) { create(:character, name: "Returner") }
  let(:context) { described_class.new(character:) }

  it "normalizes and resolves every allowlisted destination" do
    expect(context.path_for("world")).to eq(world_path)
    expect(context.path_for("inventory")).to eq(inventory_path)
    expect(context.path_for("profile")).to eq(player_path(name: character.name))
  end

  it "defaults a null destination to the world" do
    expect(context.normalize(nil)).to eq("name" => "world")
  end

  it "rejects arbitrary destinations and safely falls back for persisted metadata" do
    expect { context.normalize("https://example.test") }
      .to raise_error(described_class::UnsupportedContextError)
    expect(context.path_for("https://example.test")).to eq(world_path)
  end
end
