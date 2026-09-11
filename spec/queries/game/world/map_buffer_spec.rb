# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::MapBuffer do
  include ActiveSupport::Testing::TimeHelpers
  let(:zone) { create(:zone, location_type: "outdoor", width: 1000, height: 1000) }
  let(:position) { create(:character_position, zone:, x: 20, y: 20) }

  def buffer(token: nil)
    described_class.new(position:, token:, columns: 13, rows: 7).call
  end

  it "bootstraps with only a 5-by-7 buffer until the client supplies its viewport" do
    result = described_class.new(position:).call

    expect(result).to have_attributes(visible_columns: 3, visible_rows: 5, width: 5, height: 7)
    expect(result.rows.flatten.size).to eq(35)
  end

  it "sizes desktop and phone buffers from validated whole odd cells" do
    [[17, 5, 133], [3, 5, 35], [39, 9, 451]].each do |columns, rows, count|
      result = described_class.new(position:, columns: columns.to_s, rows: rows.to_s).call
      expect(result).to have_attributes(visible_columns: columns, visible_rows: rows)
      expect(result.rows.flatten.size).to eq(count)
    end
    [nil, "", "9.0", [], {}, -3, 0, 2, 4, 100_001, "3 OR 1=1"].each do |invalid|
      result = described_class.new(position:, columns: invalid, rows: invalid).call
      expect(result).to have_attributes(visible_columns: 3, visible_rows: 5)
      expect(result.rows.flatten.size).to eq(35)
    end
  end

  it "rebuilds a resized viewport rather than interpreting its token with new dimensions" do
    desktop = described_class.new(position:, columns: 17, rows: 5).call
    phone = described_class.new(position:, columns: 3, rows: 5, token: desktop.token).call

    expect(phone.base_token).to be_nil
    expect(phone.rows.flatten.size).to eq(35)
    expect(described_class.new(position:, columns: 3, rows: 5, token: phone.token).call.rows.flatten).to be_empty
  end

  it "bounds the full snapshot to 135 cells even in a million-cell sparse region" do
    result = buffer

    expected_rows = (16..24).map { |y| (13..27).map { |x| [x, y] } }
    expect(result.rows.map { |row| row.map { |tile| [tile.x, tile.y] } }).to eq(expected_rows)
    expect(result.base_token).to be_nil
  end

  it "sends no terrain again when the accepted movement retains its source center" do
    original = buffer

    result = buffer(token: original.token)

    expect(result.rows).to eq(Array.new(9) { [] })
    expect(result.base_token).to eq(original.token)
  end

  it "keeps empty rows before the new southern edge, ordered west to east" do
    original = buffer
    position.update!(y: 21)

    result = buffer(token: original.token)

    expected_rows = Array.new(8) { [] } + [(13..27).map { |x| [x, 25] }]
    expect(result.rows.map { |row| row.map { |tile| [tile.x, tile.y] } }).to eq(expected_rows)
  end

  it "orders diagonal entering cells north to south without duplicating the corner" do
    original = buffer
    position.update!(x: 21, y: 21)

    result = buffer(token: original.token)

    expected_rows = (17..24).map { |y| [[28, y]] } + [(14..28).map { |x| [x, 25] }]
    expect(result.rows.map { |row| row.map { |tile| [tile.x, tile.y] } }).to eq(expected_rows)
  end

  it "signs the current buffer identity and returns a microsecond server revision" do
    position
    instant = Time.utc(2026, 9, 9, 12, 0, 0, 123456)

    travel_to(instant, with_usec: true) do
      result = buffer
      payload = Rails.application.message_verifier("world-map-buffer").verified(result.token)

      expect(payload).to match(
        "character_id" => position.character_id, "zone_id" => zone.id,
        "columns" => 13, "rows" => 7,
        "x" => 20, "y" => 20, "fingerprint" => a_string_matching(/\A[0-9a-f]{64}\z/)
      )
      expect(result.revision).to eq(1_788_955_200_123_456)
    end
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

  it "projects the loaded entrance key separately from forged cell metadata" do
    create(:map_tile_template, zone: zone.name, x: 20, y: 20,
      metadata: {"building_key" => "outpost_gate"})
    cell = buffer.rows.flatten.find { |entry| entry.x == 20 && entry.y == 20 }
    expect(cell.building_key).to be_nil

    building = create(:tile_building, zone: zone.name, x: 20, y: 20, building_key: "managed_gate")
    cell = buffer.rows.flatten.find { |entry| entry.x == 20 && entry.y == 20 }
    expect(cell.building_key).to eq("managed_gate")
    expect(cell.metadata["building_key"]).to eq("outpost_gate")

    building.update!(x: 21)
    result = buffer
    expect(result.rows.flatten.find { |entry| entry.x == 20 && entry.y == 20 }.building_key).to be_nil
    expect(result.rows.flatten.find { |entry| entry.x == 21 && entry.y == 20 }.building_key).to eq("managed_gate")
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
    travel 29.minutes do
      expect(buffer(token: original.token).base_token).to eq(original.token)
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

  it "reads only the 16 by 10 union of adjacent buffers when moving diagonally" do
    original = buffer
    position.update!(x: 21, y: 21)
    queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) { queries << payload if payload[:sql].match?(/SELECT.*(?:map_tile_templates|tile_buildings|tile_npcs)/) }

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { buffer(token: original.token) }

    expect(queries.size).to eq(2)
    queries.each do |query|
      expect(query[:sql]).not_to include("tile_npcs")
      expect(query[:binds].select { |bind| bind.name == "x" }.map(&:value_for_database)).to eq([13, 28])
      expect(query[:binds].select { |bind| bind.name == "y" }.map(&:value_for_database)).to eq([16, 25])
    end
  end
end
