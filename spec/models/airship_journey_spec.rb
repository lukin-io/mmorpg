# frozen_string_literal: true

require "rails_helper"

RSpec.describe AirshipJourney do
  it "derives wait, flight, and arrived aboard at exact server boundaries" do
    journey = create(:airship_journey)
    expect(journey.phase(at: journey.departs_at - 0.001)).to eq(:waiting)
    expect(journey.phase(at: journey.departs_at)).to eq(:in_flight)
    expect(journey.phase(at: journey.arrives_at - 0.001)).to eq(:in_flight)
    expect(journey.phase(at: journey.arrives_at)).to eq(:arrived)
    expect(journey).to be_aboard
    expect(journey.progress(at: journey.departs_at - 1.day)).to eq(0)
    expect(journey.progress(at: journey.arrives_at + 1.day)).to eq(1)
  end

  it "rejects changes to accepted fare, deadline, destination, and path snapshots" do
    journey = create(:airship_journey)
    [
      {fare_nv: 151}, {arrives_at: journey.arrives_at + 1}, {destination_x: 2},
      {waypoints: journey.waypoints.map { |point| point.merge("x" => 8) }}
    ].each do |changes|
      expect(journey.reload.update(changes)).to be false
      expect(journey.errors[:base]).to include("Accepted flight details cannot change")
    end
  end

  it "rejects malformed, non-increasing, unbounded or foreign-region paths" do
    journey = build(:airship_journey)
    valid = journey.waypoints
    [
      [], "bad", [nil, nil], Array.new(129, valid.first),
      [valid.first, valid.last.merge("offset_seconds" => 0)],
      [valid.first.merge("x" => -1), valid.last],
      [valid.first.merge("zone_id" => -1), valid.last],
      [valid.first.merge("zone_id" => journey.source_zone.id), valid.last],
      [valid.first, valid.last.merge("x" => 1000)],
      [valid.first, valid.last.merge("offset_seconds" => 239)]
    ].each do |points|
      journey.waypoints = points
      expect(journey).not_to be_valid
      expect(journey.errors[:waypoints]).to be_present
    end
  end

  it "rejects invalid destination coordinates" do
    journey = build(:airship_journey, destination_x: 1000)
    expect(journey).not_to be_valid
    expect(journey.errors[:base]).to include("Flight endpoints must be valid city cells")
  end

  it "does not reopen a terminal journey" do
    journey = create(:airship_journey)
    journey.update!(status: :cancelled, disembarked_at: Time.current)
    expect(journey.update(status: :aboard)).to be false
    expect(journey.errors[:status]).to include("cannot reopen a finished journey")
  end

  it "enforces one active journey per character at the database boundary" do
    journey = create(:airship_journey)
    expect do
      described_class.transaction(requires_new: true) { create(:airship_journey, character: journey.character) }
    end.to raise_error(ActiveRecord::RecordNotUnique)
    expect(described_class.aboard.where(character: journey.character).count).to eq(1)
  end

  it "identifies a flight by its route and exact departure rather than current cell" do
    journey = create(:airship_journey)
    flight_key = journey.flight_key
    journey.update!(last_position_x: 5)
    expect(journey.flight_key).to eq(flight_key)
    expect(flight_key).to eq("#{journey.route_key}:#{journey.departs_at.utc.iso8601(6)}")
  end
end
