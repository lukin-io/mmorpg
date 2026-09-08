# frozen_string_literal: true

# A paid, immutable flight reservation. Waiting, flight, and arrival aboard are
# projections of server timestamps; only explicit disembarkation ends the trip.
# Waypoints describe authoritative region-local cells, never a map transform.
class AirshipJourney < ApplicationRecord
  MAX_WAYPOINTS = 128
  SNAPSHOT_ATTRIBUTES = %w[
    character_id boarding_offer_id source_zone_id source_x source_y
    destination_zone_id destination_x destination_y route_key route_label
    fare_nv boarded_at departs_at arrives_at waypoints
  ].freeze
  PathPosition = Data.define(:zone_id, :x, :y)

  belongs_to :character
  belongs_to :boarding_offer, class_name: "WorldActionOffer"
  belongs_to :source_zone, class_name: "Zone"
  belongs_to :destination_zone, class_name: "Zone"
  belongs_to :last_position_zone, class_name: "Zone"

  enum :status, {aboard: 0, disembarked: 1, cancelled: 2, failed: 3}

  validates :route_key, format: {with: /\A[a-z][a-z0-9_]{0,63}\z/}
  validates :route_label, presence: true
  validates :fare_nv, numericality: {greater_than: 0}
  validates :source_x, :source_y, :destination_x, :destination_y,
    :last_position_x, :last_position_y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :boarding_offer_id, uniqueness: true
  validates :boarded_at, :departs_at, :arrives_at, presence: true
  validate :ordered_deadlines
  validate :immutable_reservation
  validate :valid_endpoints, on: :create
  validate :valid_path, on: :create

  def phase(at: Time.current)
    return status.to_sym unless aboard?
    return :waiting if at < departs_at
    return :in_flight if at < arrives_at

    :arrived
  end

  def flight_key
    "#{route_key}:#{departs_at.utc.iso8601(6)}"
  end

  def progress(at: Time.current)
    ((at - departs_at) / (arrives_at - departs_at)).clamp(0.0, 1.0)
  end

  # Same-region segments interpolate; a region boundary selects the explicitly
  # authored next waypoint at its timestamp, with no inferred coordinate map.
  def path_position(at: Time.current)
    elapsed = (at - departs_at).clamp(0, arrives_at - departs_at)
    index = waypoints.rindex { |point| point.fetch("offset_seconds") <= elapsed } || 0
    point = waypoints.fetch(index)
    following = waypoints[index + 1]
    fraction = if following && following.fetch("zone_id") == point.fetch("zone_id")
      (elapsed - point.fetch("offset_seconds")) / (following.fetch("offset_seconds") - point.fetch("offset_seconds")).to_f
    else
      0
    end
    PathPosition.new(
      zone_id: point.fetch("zone_id"),
      x: point.fetch("x") + fraction * ((following || point).fetch("x") - point.fetch("x")),
      y: point.fetch("y") + fraction * ((following || point).fetch("y") - point.fetch("y"))
    )
  end

  private

  def ordered_deadlines
    return unless boarded_at && departs_at && arrives_at

    errors.add(:departs_at, "must follow boarding and precede arrival") unless boarded_at <= departs_at && departs_at < arrives_at
  end

  def immutable_reservation
    return unless persisted?

    if SNAPSHOT_ATTRIBUTES.any? { |attribute| will_save_change_to_attribute?(attribute) }
      errors.add(:base, "Accepted flight details cannot change")
    end
    if status_in_database != "aboard" && will_save_change_to_status?
      errors.add(:status, "cannot reopen a finished journey")
    end
  end

  def valid_endpoints
    [[source_zone, source_x, source_y], [destination_zone, destination_x, destination_y]].each do |zone, x, y|
      next if zone&.city? && x.is_a?(Integer) && y.is_a?(Integer) && x.between?(0, zone.width - 1) && y.between?(0, zone.height - 1)

      errors.add(:base, "Flight endpoints must be valid city cells")
    end
  end

  def valid_path
    unless waypoints.is_a?(Array) && waypoints.size.between?(2, MAX_WAYPOINTS) && departs_at && arrives_at
      errors.add(:waypoints, "must contain a bounded timed route")
      return
    end
    unless waypoints.all? { |point| point.is_a?(Hash) && %w[offset_seconds zone_id x y].all? { |key| point[key].is_a?(Integer) } }
      errors.add(:waypoints, "must contain integer offsets, region ids, and coordinates")
      return
    end
    offsets = waypoints.pluck("offset_seconds")
    unless offsets.first == 0 && offsets.last == (arrives_at - departs_at) && offsets.each_cons(2).all? { |left, right| right > left }
      errors.add(:waypoints, "must span the flight in strictly increasing order")
    end
    zones = Zone.where(id: waypoints.pluck("zone_id").uniq).index_by(&:id)
    waypoints.each do |point|
      zone = zones[point.fetch("zone_id")]
      next if zone&.outdoor? && point.fetch("x").between?(0, zone.width - 1) && point.fetch("y").between?(0, zone.height - 1)

      errors.add(:waypoints, "must stay within authored outdoor regions")
      break
    end
  end
end
