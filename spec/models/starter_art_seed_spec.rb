# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/world_content_support")

RSpec.describe "Starter landscape seed upgrade", type: :model do
  let!(:zone) { create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings") }

  def load_cells
    load Rails.root.join("db/seeds/world_cells.rb")
  end

  it "maps every surveyed coordinate once onto its landscape without changing surveyed passability" do
    load_cells
    cells = MapTileTemplate.where(zone: zone.name).order(:y, :x).to_a

    expect(cells.size).to eq(273)
    cells.each do |cell|
      expected_art = if cell.x == 20 && [6, 7].include?(cell.y)
        {"key" => "forpost_ogre_habitat", "column" => 0, "row" => cell.y - 6}
      else
        {"key" => "forpost_starter", "column" => cell.x, "row" => cell.y - 2}
      end
      expect(cell.cell_art).to eq(expected_art)
      expect(cell.cell_art_presentation).to have_attributes(
        physical_slice: true, landmarks_in_art: expected_art.fetch("key") == "forpost_starter"
      )
      expect(cell.passable).to eq(Game::World::StarterCellCatalog.default.at(cell.x, cell.y).passable)
    end
    expect(cells.map(&:cell_art).uniq.size).to eq(273)
    expect { load_cells }.not_to change { MapTileTemplate.order(:id).pluck(:updated_at) }
  end

  it "upgrades legacy sheet references while preserving edited cell layers and saved positions" do
    load_cells
    cell = MapTileTemplate.find_by!(zone: zone.name, x: 12, y: 10)
    cell.update!(passable: false, metadata: cell.metadata.merge(
      "cell_art" => {"key" => "forpost_pond", "column" => 1, "row" => 2},
      "presence_label" => "Managed bank", "resource_groups" => [],
      "local_actions" => [{"type" => "digging", "source_id" => "dig", "active" => false}]
    ))
    original = cell.attributes.except("metadata", "updated_at")
    metadata = cell.metadata.except("cell_art")
    position = create(:character_position, zone:, x: 12, y: 10)

    load_cells

    expect(cell.reload.cell_art).to eq("key" => "forpost_starter", "column" => 12, "row" => 8)
    expect(cell.attributes.except("metadata", "updated_at")).to eq(original)
    expect(cell.metadata.except("cell_art")).to eq(metadata)
    expect(position.reload).to have_attributes(zone:, x: 12, y: 10)
  end

  it "preserves independent art and edited starter references instead of reconciling them on every seed" do
    config = Game::World::CellArtCatalog.config.deep_dup
    config["independent_landscape"] = config.fetch("forpost_terrain").deep_dup
    allow(Game::World::CellArtCatalog).to receive(:config).and_return(config)
    load_cells
    independent = MapTileTemplate.find_by!(zone: zone.name, x: 13, y: 10)
    independent.update!(passable: false, metadata: independent.metadata.merge(
      "cell_art" => {"key" => "independent_landscape", "column" => 3, "row" => 4}
    ))
    edited = MapTileTemplate.find_by!(zone: zone.name, x: 3, y: 3)
    edited.update!(metadata: edited.metadata.merge("cell_art" => {"key" => "forpost_starter", "column" => 4, "row" => 5}))
    originals = [independent, edited].map(&:attributes)

    load_cells

    expect([independent, edited].map { |cell| cell.reload.attributes }).to eq(originals)
  end

  it "adds the captured intermediate village label without an entrance or overriding an edited label" do
    load_cells
    cell = MapTileTemplate.find_by!(zone: zone.name, x: 5, y: 7)
    character = create(:character)
    position = create(:character_position, character:, zone:, x: 5, y: 7)

    expect(cell.metadata["presence_label"]).to eq("Frontier Village")
    expect(Game::World::Presence.new(character:, position:).label).to eq("Frontier Village")
    expect(TileBuilding.where(zone: zone.name, x: 5, y: 7)).to be_empty
    expect(cell.active_local_actions).to be_empty
    cell.update!(metadata: cell.metadata.merge("presence_label" => "Managed village approach"))
    original = cell.attributes

    load_cells

    expect(cell.reload.attributes).to eq(original)
    expect(Game::World::Presence.new(character:, position:).label).to eq("Managed village approach")
  end
end
