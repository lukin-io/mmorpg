# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::MapBuffer do
  include ActiveSupport::Testing::TimeHelpers
  let(:zone) { create(:zone, location_type: "outdoor", width: 1000, height: 1000) }
  let(:position) { create(:character_position, zone:, x: 20, y: 20) }

  def buffer(token: nil)
    described_class.new(position:, token:).call
  end

  it "bounds the full snapshot to 135 cells even in a million-cell sparse region" do
    result = buffer

    expect(result.rows.flatten.size).to eq(135)
    expect(result.rows.flatten.map(&:x).minmax).to eq([13, 27])
    expect(result.rows.flatten.map(&:y).minmax).to eq([16, 24])
    expect(result.base_token).to be_nil
  end

  it "sends no terrain again when the accepted movement retains its source center" do
    original = buffer

    expect(buffer(token: original.token).rows.flatten).to be_empty
  end

  Game::Movement::Directions::OFFSETS.each do |direction, (dx, dy)|
    it "sends only entering cells when walking #{direction}" do
      original = buffer
      original_coordinates = original.rows.flatten.map { |tile| [tile.x, tile.y] }
      position.update!(x: 20 + dx, y: 20 + dy)

      result = buffer(token: original.token)
      expected_count = if dx.zero?
        15
      elsif dy.zero?
        9
      else
        23
      end
      expect(result.rows.flatten.size).to eq(expected_count)
      expect(result.rows.flatten.map { |tile| [tile.x, tile.y] } & original_coordinates).to be_empty
      expect(result.base_token).to eq(original.token)
    end
  end

  it "invalidates reuse when an overlapping authored cell changes, including a callback-free maintenance edit" do
    tile = create(:map_tile_template, zone: zone.name, x: 20, y: 20, passable: true)
    original = buffer
    tile.update_columns(passable: false)

    result = buffer(token: original.token)

    expect(result.base_token).to be_nil
    expect(result.rows.flatten.size).to eq(135)
    expect(result.rows.flatten.find { |cell| cell.x == 20 && cell.y == 20 }.passable).to be(false)
  end

  it "invalidates reuse after deletion of a visible building" do
    building = create(:tile_building, zone: zone.name, x: 20, y: 20)
    original = buffer
    building.destroy!

    result = buffer(token: original.token)

    expect(result.base_token).to be_nil
    expect(result.rows.flatten.find { |cell| cell.x == 20 && cell.y == 20 }.metadata).not_to have_key("building")
  end

  it "renders a newly entering building without rebuilding the unchanged overlap" do
    original = buffer
    create(:tile_building, zone: zone.name, x: 28, y: 20, name: "Eastern Village")
    position.update!(x: 21)

    result = buffer(token: original.token)

    expect(result.rows.flatten.size).to eq(9)
    expect(result.rows.flatten.find { |cell| cell.y == 20 }.metadata["building"]).to eq("Eastern Village")
  end

  it "keeps the edge placeholders inert while extending the buffer at the region origin" do
    position.update!(x: 0, y: 0)
    original = buffer
    position.update!(x: 1, y: 1)

    result = buffer(token: original.token)

    expect(result.rows.flatten.size).to eq(23)
    expect(result.rows.flatten.select { |tile| tile.x.negative? || tile.y.negative? }).to all(have_attributes(walkable: false, passable: false))
  end

  it "does not reuse another character's or another region's buffer" do
    original = buffer
    foreign = create(:character_position, zone:, x: 20, y: 20)
    expect(described_class.new(position: foreign, token: original.token).call.base_token).to be_nil

    position.update!(zone: create(:zone, location_type: "outdoor", width: 1000, height: 1000))
    expect(buffer(token: original.token).base_token).to be_nil
  end

  it "falls back to a full snapshot for malformed, expired, or distant hints" do
    original = buffer
    [nil, {}, "broken", "x" * 2049].each do |token|
      expect(buffer(token:).rows.flatten.size).to eq(135)
    end
    travel 31.minutes do
      expect(buffer(token: original.token).base_token).to be_nil
    end
    position.update!(x: 30)
    expect(buffer(token: original.token).base_token).to be_nil
  end

  it "uses only two bounded content reads and does not query hidden NPCs" do
    position.zone
    queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] if payload[:sql].match?(/SELECT.*(?:map_tile_templates|tile_buildings|tile_npcs)/) }

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { buffer }

    expect(queries.size).to eq(2)
    expect(queries).to all(include("BETWEEN"))
    expect(queries.join).not_to include("tile_npcs")
  end
end
