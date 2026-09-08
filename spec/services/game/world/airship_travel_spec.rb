# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::AirshipTravel do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.current.change(usec: 0) }
  let(:character) { create(:character) }
  let(:source) { create(:zone, :city, name: "Flight Source") }
  let(:destination) { create(:zone, :city, name: "Flight Destination") }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let(:other_region) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: source, x: 1, y: 2) }
  let!(:source_station) { create(:city_hotspot, zone: source, action_params: {feature: "airship_station"}) }
  let!(:destination_station) { create(:city_hotspot, zone: destination, action_params: {feature: "airship_station"}) }
  let(:departure) { now + 60 }
  let(:definition) do
    {
      "source_zone" => source.name, "destination_zone" => destination.name,
      "destination_x" => 3, "destination_y" => 4, "label" => "Destination",
      "route_label" => "Route Source - Destination", "fare_nv" => 150,
      "departures" => [departure.iso8601(6)], "duration_seconds" => 240,
      "waypoints" => [
        {"offset_seconds" => 0, "zone" => region.name, "x" => 5, "y" => 5},
        {"offset_seconds" => 120, "zone" => region.name, "x" => 17, "y" => 5},
        {"offset_seconds" => 180, "zone" => other_region.name, "x" => 2, "y" => 8},
        {"offset_seconds" => 240, "zone" => other_region.name, "x" => 2, "y" => 14}
      ]
    }
  end
  let(:routes) { Game::World::AirshipRoutes.new(config: {"source_destination" => definition}) }
  let(:travel) { described_class.new(character:, routes:) }
  let(:wallet) { character.user.currency_wallet }

  before do
    wallet.update!(nv_balance: 500)
    travel_to now
  end

  after { travel_back }

  def board
    travel.board!(action_key: travel.station_routes!.sole.action_key)
  end

  it "boards once, debits and audits the fare, and persists one resumable flight context" do
    offer = travel.station_routes!.sole
    expect(offer.available).to be true
    expect(travel.station_routes!.sole.action_key).to eq(offer.action_key)
    journey = travel.board!(action_key: offer.action_key)

    expect(wallet.reload.nv_balance).to eq(350)
    expect(wallet.currency_transactions.sole).to have_attributes(amount: -150, reason: "airship_boarding", balance_after: 350)
    expect(wallet.currency_transactions.sole.metadata["airship_journey_id"]).to eq(journey.id)
    expect(position.reload).to have_attributes(zone: source, x: 1, y: 2)
    expect(character.reload.gameplay_context).to eq("name" => "airship", "params" => {"journey_id" => journey.id})
    expect(travel.board!(action_key: offer.action_key)).to eq(journey)
    expect(wallet.reload.currency_transactions.count).to eq(1)
    expect(AirshipJourney.where(character:).count).to eq(1)
  end

  it "never offers or charges a fare with an unresolved destination" do
    definition["destination_zone"] = "Unpopulated Oktal"
    expect(travel.station_routes!.sole).to have_attributes(available: false, action_key: nil)
    expect { travel.board!(action_key: "forged") }.to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
    expect(AirshipJourney.count).to eq(0)
  end

  it "rejects a foreign character's key without accepting the offer" do
    offer = travel.station_routes!.sole
    foreign = create(:character)
    create(:character_position, character: foreign, zone: source, x: 1, y: 2)
    expect { described_class.new(character: foreign, routes:).board!(action_key: offer.action_key) }
      .to raise_error(described_class::TravelViolationError)
    expect(WorldActionOffer.find_by!(action_key: offer.action_key)).to be_offered
    expect(wallet.reload.nv_balance).to eq(500)
  end

  it "rejects an old source-cell offer after authoritative relocation" do
    key = travel.station_routes!.sole.action_key
    position.update!(x: 2)
    expect { travel.board!(action_key: key) }.to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
    expect(position.reload.x).to eq(2)
  end

  it "rejects a changed fare instead of silently charging a new quote" do
    key = travel.station_routes!.sole.action_key
    changed = Game::World::AirshipRoutes.new(config: {"source_destination" => definition.merge("fare_nv" => 151)})
    expect { described_class.new(character:, routes: changed).board!(action_key: key) }
      .to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
  end

  it "rejects a missed departure at its exact server boundary" do
    key = travel.station_routes!.sole.action_key
    travel_to departure
    expect { travel.board!(action_key: key) }.to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
  end

  it "rolls the reservation and offer back on insufficient funds" do
    key = travel.station_routes!.sole.action_key
    wallet.update!(nv_balance: 149)
    expect { travel.board!(action_key: key) }.to raise_error(Economy::WalletService::InsufficientFundsError)
    expect(AirshipJourney.count).to eq(0)
    expect(WorldActionOffer.find_by!(action_key: key)).to be_offered
    expect(wallet.reload.currency_transactions.count).to eq(0)
  end

  it "rolls payment, reservation and offer back if the new chat context cannot persist" do
    key = travel.station_routes!.sole.action_key
    allow(Chat::LocalContext).to receive(:new).and_raise(ActiveRecord::StatementInvalid, "context unavailable")
    expect { travel.board!(action_key: key) }.to raise_error(ActiveRecord::StatementInvalid)
    expect(AirshipJourney.count).to eq(0)
    expect(WorldActionOffer.find_by!(action_key: key)).to be_offered
    expect(wallet.reload.nv_balance).to eq(500)
    expect(wallet.currency_transactions.count).to eq(0)
  end

  it "rejects pending Arena applications before taking money" do
    create(:city_hotspot, zone: source, action_params: {feature: "arena"})
    key = travel.station_routes!.sole.action_key
    create(:arena_application, applicant: character)
    expect { travel.board!(action_key: key) }.to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
  end

  it "rejects an ordinary moving command before taking money" do
    key = travel.station_routes!.sole.action_key
    create(:movement_command, :moving, character:, zone: source, from_x: 1, from_y: 2)
    expect { travel.board!(action_key: key) }.to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
  end

  it "rejects an active fight before taking money" do
    key = travel.station_routes!.sole.action_key
    create(:arena_participation, character:, user: character.user, arena_match: create(:arena_match, :live))
    expect { travel.board!(action_key: key) }.to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
  end

  it "rejects an active Look before taking money" do
    key = travel.station_routes!.sole.action_key
    create(:world_action_offer, :accepted, character:, zone: source, x: 1, y: 2,
      metadata: {"local_action_ends_at" => (now + 28).iso8601(6), "local_action_result" => "No vegetation."})
    expect { travel.board!(action_key: key) }.to raise_error(described_class::TravelViolationError)
    expect(wallet.reload.nv_balance).to eq(500)
  end

  it "resumes the same wait with a bounded seven-by-three map after reload" do
    journey = board
    travel_to now + 20
    state = described_class.new(character: character.reload, routes:).state
    expect(state).to have_attributes(journey:, phase: :waiting, remaining_seconds: 40, can_disembark: true, confirm_disembark: true)
    expect(state.map).to have_attributes(columns: 7, rows: 3, center_x: 5, center_y: 5, velocity_x: 0, velocity_y: 0)
    expect(state.map.tiles.flatten.size).to eq(21)
    expect(position.reload.zone).to eq(source)
  end

  it "persists departure and sampled flight cells from the server clock" do
    journey = board
    travel_to departure
    expect(travel.state).to have_attributes(phase: :in_flight, remaining_seconds: 240, can_disembark: false)
    expect(position.reload).to have_attributes(zone: region, x: 5, y: 5)
    travel_to departure + 65
    state = described_class.new(character: character.reload, routes:).state
    expect(position.reload).to have_attributes(zone: region, x: 12, y: 5)
    expect(state.map).to have_attributes(columns: 11, rows: 5, center_x: 11.5, velocity_x: 0.1, velocity_y: 0)
    expect(state.map.tiles.flatten.size).to eq(55)
    expect(journey.reload).to have_attributes(last_position_zone: region, last_position_x: 12)
    expect(wallet.reload.nv_balance).to eq(350)
  end

  %i[reconcile! state].each do |entry_point|
    it "samples the clock after obtaining the character lock for #{entry_point}, avoiding a queued request rewind" do
      board
      travel.reconcile!(at: departure + 60)
      expect(position.reload.x).to eq(11)

      server_now = departure + 20
      queued_request = described_class.new(character: character.reload, routes:, clock: -> { server_now })
      # Simulate time spent obtaining the real PostgreSQL row lock. An older
      # request must use the clock after acquisition, not its queued timestamp.
      acquired_lock = lambda do |event|
        server_now = departure + 70 if event.payload[:sql].match?(/FROM "characters".*FOR UPDATE/)
      end
      ActiveSupport::Notifications.subscribed(acquired_lock, "sql.active_record") do
        queued_request.public_send(entry_point)
      end

      expect(position.reload).to have_attributes(zone: region, x: 12, y: 5)
    end
  end

  it "crosses only the explicitly authored region waypoint without an inferred coordinate transform" do
    board
    travel_to departure + 179
    travel.reconcile!
    expect(position.reload).to have_attributes(zone: region, x: 17, y: 5)
    travel_to departure + 180
    travel.reconcile!
    expect(position.reload).to have_attributes(zone: other_region, x: 2, y: 8)
    travel_to departure + 210
    travel.reconcile!
    expect(position.reload).to have_attributes(zone: other_region, x: 2, y: 11)
  end

  it "catches up offline flight at arrival but stays aboard until explicit disembarkation" do
    journey = board
    travel_to journey.arrives_at + 1.hour
    state = travel.state
    expect(state).to have_attributes(phase: :arrived, remaining_seconds: 0, deadline: nil, can_disembark: true, confirm_disembark: false)
    expect(state.map).to have_attributes(columns: 7, rows: 3)
    expect(position.reload).to have_attributes(zone: other_region, x: 2, y: 14)
    expect(journey.reload).to be_aboard
    result = travel.disembark!(journey_id: journey.id)
    expect(result).to be_disembarked
    expect(position.reload).to have_attributes(zone: destination, x: 3, y: 4)
    expect(character.reload.gameplay_context).to eq("name" => "city_building", "params" => {"building_key" => "airship_station"})
    arrival = position.attributes.slice("zone_id", "x", "y", "last_action_at")
    travel.disembark!(journey_id: journey.id)
    expect(position.reload.attributes.slice(*arrival.keys)).to eq(arrival)
    expect(wallet.reload.currency_transactions.count).to eq(1)
  end

  it "allows confirmed waiting cancellation without a refund" do
    journey = board
    travel_to departure - 1
    expect(travel.disembark!(journey_id: journey.id)).to be_cancelled
    expect(position.reload).to have_attributes(zone: source, x: 1, y: 2)
    expect(wallet.reload.nv_balance).to eq(350)
    expect(travel.state).to be_nil
  end

  it "rejects disembarkation at exact departure and allows it at exact arrival" do
    journey = board
    travel_to departure
    expect { travel.disembark!(journey_id: journey.id) }.to raise_error(described_class::TravelViolationError)
    expect(journey.reload).to be_aboard
    travel_to journey.arrives_at
    expect(travel.disembark!(journey_id: journey.id)).to be_disembarked
    expect(position.reload.zone).to eq(destination)
  end

  it "rejects another character's journey id" do
    journey = board
    foreign = create(:character)
    expect { described_class.new(character: foreign, routes:).disembark!(journey_id: journey.id) }
      .to raise_error(described_class::TravelViolationError)
    expect(journey.reload).to be_aboard
  end

  it "rolls arrival and flight completion back if room/chat persistence fails" do
    journey = board
    travel_to journey.arrives_at
    travel.reconcile!
    allow(Chat::LocalContext).to receive(:new).and_raise(ActiveRecord::StatementInvalid, "context unavailable")
    expect { travel.disembark!(journey_id: journey.id) }.to raise_error(ActiveRecord::StatementInvalid)
    expect(position.reload).to have_attributes(zone: other_region, x: 2, y: 14)
    expect(journey.reload).to be_aboard
    expect(journey.boarding_offer).to be_accepted
    expect(wallet.reload.nv_balance).to eq(350)
  end

  it "fails a stale journey durably while preserving an externally relocated position" do
    journey = board
    position.update!(zone: other_region, x: 99, y: 88)
    expect(travel.reconcile!).to be_nil
    expect(journey.reload).to be_failed
    expect(journey.error_message).to include("Position changed")
    expect(position.reload).to have_attributes(zone: other_region, x: 99, y: 88)
    expect(character.reload.gameplay_context["name"]).to eq("world")
    expect(travel.state).to be_nil
    expect(wallet.reload.nv_balance).to eq(350)
  end

  it "fails a journey with a removed future region without stranding every reload" do
    journey = board
    other_region.destroy!
    expect(travel.reconcile!).to be_nil
    expect(journey.reload).to be_failed
    expect(position.reload.zone).to eq(source)
    expect(travel.state).to be_nil
    expect(wallet.reload.nv_balance).to eq(350)
  end

  it "uses the accepted waypoint snapshot after route configuration changes" do
    journey = board
    definition["waypoints"][1]["x"] = 100
    travel_to departure + 60
    expect(described_class.new(character:, routes: Game::World::AirshipRoutes.new(config: {})).reconcile!).to eq(journey)
    expect(position.reload).to have_attributes(zone: region, x: 11, y: 5)
  end

  it "bounds map queries to the current region and window" do
    board
    travel_to departure + 60
    create(:map_tile_template, zone: region.name, x: 11, y: 5,
      metadata: {source_map: "m_11_5", cell_art: {key: "forpost_terrain", column: 1, row: 0}})
    create(:map_tile_template, zone: other_region.name, x: 11, y: 5,
      metadata: {source_map: "m_11_5", cell_art: {key: "forpost_terrain", column: 2, row: 0}})
    create(:map_tile_template, zone: region.name, x: 999, y: 999)
    reads = []
    rows = []
    query_subscriber = ->(event) { reads << event.payload[:sql] if event.payload[:sql].match?(/\ASELECT .*FROM "map_tile_templates"/) }
    row_subscriber = ->(event) { rows << event.payload[:record_count] if event.payload[:class_name] == "MapTileTemplate" }
    map = nil
    ActiveRecord::Base.uncached do
      ActiveSupport::Notifications.subscribed(query_subscriber, "sql.active_record") do
        ActiveSupport::Notifications.subscribed(row_subscriber, "instantiation.active_record") { map = travel.state.map }
      end
    end
    expect(map.tiles.flatten.find { |tile| tile.x == 11 && tile.y == 5 }.art.column).to eq(1)
    expect(map.tiles.flatten.size).to eq(55)
    expect(reads.size).to eq(1)
    expect(rows.sum).to eq(1)
  end

  it "leaves outside-region buffer slots empty without loading another region's terrain" do
    definition["waypoints"][0].merge!("x" => 0, "y" => 0)
    board
    travel_to departure
    map = travel.state.map
    expect(map.tiles.flatten.size).to eq(55)
    expect(map.tiles.flatten.select { |tile| tile.x.negative? || tile.y.negative? })
      .to all(have_attributes(terrain_type: "void", art: nil))
    expect(map.tiles.flatten.find { |tile| tile.x == 0 && tile.y == 0 }.terrain_type).to eq("outdoor")
  end

  # This repository's js metadata selects truncation rather than transaction
  # cleanup, making setup visible to independent PostgreSQL connections.
  context "concurrent flight actions", js: true do
    it "holds the position lock through the bounded map snapshot before another connection can disembark" do
      journey = board
      travel_to journey.arrives_at
      competing_result = nil
      snapshot = nil
      during_map_read = lambda do |event|
        next unless event.payload[:sql].match?(/\ASELECT .*FROM "map_tile_templates"/)

        worker = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            passenger = Character.find(character.id)
            # NOWAIT makes the actual competing row-lock attempt deterministic,
            # without sleeping or allowing a failed test to hang indefinitely.
            passenger.with_lock("FOR UPDATE NOWAIT") do
              competing_result = described_class.new(character: passenger, routes:).disembark!(journey_id: journey.id)
            end
          rescue => error
            competing_result = error
          end
        end
        expect(worker.join(5)).to eq(worker)
      end

      ActiveRecord::Base.uncached do
        ActiveSupport::Notifications.subscribed(during_map_read, "sql.active_record") { snapshot = travel.state }
      end

      expect(competing_result).to be_a(ActiveRecord::LockWaitTimeout)
      expect(snapshot).to have_attributes(phase: :arrived, can_disembark: true)
      expect(snapshot.position).to have_attributes(zone: other_region, x: 2, y: 14)
      expect(snapshot.map.zone).to eq(other_region)
      expect(journey.reload).to be_aboard
      expect(travel.disembark!(journey_id: journey.id)).to be_disembarked
    end

    it "serializes duplicate submissions into one charge and one journey" do
      key = travel.station_routes!.sole.action_key
      gate = Queue.new
      results = Queue.new
      workers = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            gate.pop
            results << described_class.new(character: Character.find(character.id), routes:).board!(action_key: key).id
          rescue => error
            results << error
          end
        end
      end
      2.times { gate << true }
      workers.each { |worker| expect(worker.join(10)).to eq(worker) }
      ids = 2.times.map { results.pop }
      expect(ids.uniq).to eq([AirshipJourney.find_by!(character:).id])
      expect(wallet.reload.nv_balance).to eq(350)
      expect(wallet.currency_transactions.count).to eq(1)
    end

    it "serializes competing valid route offers without two charges" do
      two_routes = Game::World::AirshipRoutes.new(config: {"one" => definition, "two" => definition.merge("route_label" => "Alternate flight")})
      keys = described_class.new(character:, routes: two_routes).station_routes!.map(&:action_key)
      gate = Queue.new
      results = Queue.new
      workers = keys.map do |key|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            gate.pop
            results << described_class.new(character: Character.find(character.id), routes: two_routes).board!(action_key: key).id
          rescue => error
            results << error
          end
        end
      end
      2.times { gate << true }
      workers.each { |worker| expect(worker.join(10)).to eq(worker) }
      outcomes = 2.times.map { results.pop }
      expect(outcomes.count { |result| result.is_a?(Integer) }).to eq(1)
      expect(outcomes.count { |result| result.is_a?(described_class::TravelViolationError) }).to eq(1)
      expect(AirshipJourney.aboard.where(character:).count).to eq(1)
      expect(wallet.reload.nv_balance).to eq(350)
      expect(wallet.currency_transactions.count).to eq(1)
    end
  end
end
