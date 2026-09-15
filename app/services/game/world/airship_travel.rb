# frozen_string_literal: true

require "securerandom"

module Game
  module World
    # Owns paid boarding, clock-based region/cell progress, and explicit
    # disembarkation. Each mutation serializes on Character, then the journey or
    # offered action, then Position/Wallet. Reload recovery uses the same clock
    # projection; no background delivery is required for correctness.
    class AirshipTravel
      class TravelViolationError < StandardError; end

      RouteOffer = Data.define(:key, :label, :fare_nv, :departs_at, :available, :action_key)
      State = Data.define(:journey, :phase, :deadline, :remaining_seconds, :progress, :position, :map, :can_disembark, :confirm_disembark)
      Map = Data.define(:zone, :center_x, :center_y, :columns, :rows, :tiles, :velocity_x, :velocity_y, :motion_ends_at)
      Tile = Data.define(:x, :y, :terrain_type, :art)

      def initialize(character:, clock: -> { Time.current }, routes: AirshipRoutes.new)
        @character = character
        @clock = clock
        @routes = routes
      end

      # Reuses unexpired, unchanged boarding offers. Missing route configuration
      # remains a visible unavailable fare, with no opaque offer and no debit.
      def station_routes!
        character.with_lock do
          position = character.position&.reload
          next [] unless position&.active?

          now = clock.call
          busy = busy?
          offers = []
          rows = routes.for_station(character:, position:, at: now).map do |route|
            available = route.available? && !busy
            offer = boarding_offer(route, position, now) if available
            offers << offer if offer
            RouteOffer.new(key: route.key, label: route.label, fare_nv: route.fare_nv,
              departs_at: route.departs_at, available:, action_key: offer&.action_key)
          end
          WorldActionOffer.offered.where(character:, action_type: "board_airship").where.not(id: offers.map(&:id))
            .update_all(status: WorldActionOffer.statuses.fetch("cancelled"), updated_at: now)
          rows
        end
      end

      # A retry of the same owned offer returns its one durable journey even
      # after disembarkation. Fare, source, schedule and path are server-owned.
      def board!(action_key:)
        character.with_lock do
          offer = WorldActionOffer.where(character:, action_type: "board_airship", action_key: action_key.to_s).lock.first
          raise TravelViolationError, "Flight offer is unavailable." unless offer

          existing = AirshipJourney.find_by(character:, boarding_offer: offer)
          next existing if existing

          now = clock.call
          position = character.position&.reload
          unless offer.offered? && offer.expires_at > now && offer.matches_position?(position) && position&.active? && !busy?
            raise TravelViolationError, "Flight offer is unavailable."
          end
          route = routes.for_station(character:, position:, at: now).find { |entry| entry.key == offer.metadata["route_key"] }
          unless route&.available? && offer.metadata == offer_metadata(route)
            raise TravelViolationError, "Flight route or departure is no longer available."
          end

          offer.accept!
          journey = AirshipJourney.create!(route.attributes.merge(character:, boarding_offer: offer, boarded_at: now))
          character.user.currency_wallet.adjust!(amount: -journey.fare_nv, reason: "airship_boarding",
            metadata: {airship_journey_id: journey.id, route_key: journey.route_key, boarding_offer_id: offer.id})
          cancel_other_offers!(offer, now)
          ResumeContext.new(character:).remember_airship!(journey:)
          journey
        end
      end

      # Reconciles only an owned active reservation and its last persisted cell.
      # External relocation or invalid/deleted path data ends the journey safely,
      # preserving the newer position and original debit instead of looping on
      # every gameplay request. The durable reason supports operator review.
      def reconcile!(at: nil)
        character.with_lock { reconcile_locked!(at: at || clock.call) }
      end

      # Samples the clock after acquiring the lock and retains that lock through
      # the bounded map read, so another request cannot rewind a queued sample or
      # mix an aboard phase with a concurrently disembarked city position.
      def state
        character.with_lock do
          now = clock.call
          journey = reconcile_locked!(at: now)
          next unless journey

          phase = journey.phase(at: now)
          deadline = case phase
          when :waiting then journey.departs_at
          when :in_flight then journey.arrives_at
          end
          State.new(journey:, phase:, deadline:, remaining_seconds: deadline ? [(deadline - now).ceil, 0].max : 0,
            progress: journey.progress(at: now), position: character.position.reload, map: map_for(journey, now),
            can_disembark: phase != :in_flight, confirm_disembark: phase == :waiting)
        end
      end

      # Waiting cancellation is explicit and has no refund. In-flight requests
      # fail. Arrival stays aboard until this owned action atomically saves the
      # destination station and its normal room/chat context.
      def disembark!(journey_id:)
        character.with_lock do
          now = clock.call
          reconcile_locked!(at: now)
          journey = AirshipJourney.where(character:, id: journey_id).lock.first
          raise TravelViolationError, "Flight is unavailable." unless journey
          next journey unless journey.aboard?

          phase = journey.phase(at: now)
          raise TravelViolationError, "Disembarkation is unavailable during flight." if phase == :in_flight

          zone, x, y = if phase == :waiting
            [journey.source_zone, journey.source_x, journey.source_y]
          else
            [journey.destination_zone, journey.destination_x, journey.destination_y]
          end
          unless routes.station_available?(zone, character) && x.between?(0, zone.width - 1) && y.between?(0, zone.height - 1)
            raise TravelViolationError, "Arrival station is unavailable."
          end
          character.position.lock!.update!(zone:, x:, y:, last_action_at: now)
          journey.update!(status: phase == :waiting ? :cancelled : :disembarked, disembarked_at: now)
          journey.boarding_offer.complete!
          ResumeContext.new(character:).remember_city_building!(building_key: "airship_station")
          journey
        end
      end

      private

      attr_reader :character, :clock, :routes

      def reconcile_locked!(at:)
        journey = AirshipJourney.aboard.where(character:).lock.first
        return unless journey

        position = character.position&.lock!
        unless position&.active? && [position.zone_id, position.x, position.y] ==
            [journey.last_position_zone_id, journey.last_position_x, journey.last_position_y]
          fail_journey!(journey, "Position changed outside the accepted flight.")
          return
        end
        path_zones = valid_path_zones(journey)
        unless path_zones
          fail_journey!(journey, "Accepted flight path is no longer available.")
          return
        end
        unless journey.phase(at: at) == :waiting
          sampled = journey.path_position(at: at)
          zone = path_zones.fetch(sampled.zone_id)
          coordinates = {zone:, x: sampled.x.round, y: sampled.y.round}
          if [position.zone_id, position.x, position.y] != [zone.id, coordinates[:x], coordinates[:y]]
            position.update!(coordinates.merge(last_action_at: at))
            journey.update!(last_position_zone: zone, last_position_x: coordinates[:x], last_position_y: coordinates[:y])
            Chat::LocalContext.new(character:, clock:).synchronize!
          end
        end
        journey
      end

      def busy?
        character.active_injuries.any?(&:blocks_movement?) || AirshipJourney.aboard.where(character:).exists? || MovementCommand.moving.where(character:).exists? ||
          LocalActionState.new(character:).call.present? ||
          character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists? ||
          ArenaApplication.active.where(applicant: character).exists?
      end

      def boarding_offer(route, position, now)
        metadata = offer_metadata(route)
        WorldActionOffer.offered.at_tile(position.zone, position.x, position.y)
          .where(character:, action_type: "board_airship", metadata:).where("expires_at > ?", now).order(:id).first ||
          WorldActionOffer.create!(character:, zone: position.zone, x: position.x, y: position.y,
            action_type: "board_airship", action_key: SecureRandom.hex(16),
            expires_at: [now + WorldActionOffer::OFFER_TTL, route.departs_at].min, metadata:)
      end

      def offer_metadata(route)
        {"route_key" => route.key, "route_revision" => route.revision, "departs_at" => route.departs_at.iso8601(6)}
      end

      def cancel_other_offers!(accepted, now)
        WorldActionOffer.offered.where(character:).where.not(id: accepted.id)
          .update_all(status: WorldActionOffer.statuses.fetch("cancelled"), updated_at: now)
        MovementCommand.offered.where(character:)
          .update_all(status: MovementCommand.statuses.fetch("cancelled"), processed_at: now, updated_at: now)
      end

      def valid_path_zones(journey)
        points = journey.waypoints
        return unless points.is_a?(Array) && points.size.between?(2, AirshipJourney::MAX_WAYPOINTS)
        return unless points.all? { |point| point.is_a?(Hash) && %w[offset_seconds zone_id x y].all? { |key| point[key].is_a?(Integer) } }

        offsets = points.pluck("offset_seconds")
        return unless offsets.first == 0 && offsets.last == journey.arrives_at - journey.departs_at && offsets.each_cons(2).all? { |a, b| b > a }

        zones = Zone.where(id: points.pluck("zone_id").uniq).index_by(&:id)
        return unless points.all? do |point|
          zone = zones[point["zone_id"]]
          zone&.outdoor? && point["x"].between?(0, zone.width - 1) && point["y"].between?(0, zone.height - 1)
        end

        zones
      end

      def fail_journey!(journey, message)
        journey.update!(status: :failed, error_message: message)
        journey.boarding_offer.fail!(message)
        ResumeContext.new(character:).remember_world!
      end

      def map_for(journey, now)
        sampled = journey.path_position(at: now)
        zone = Zone.find(sampled.zone_id)
        in_flight = journey.phase(at: now) == :in_flight
        x_radius, y_radius = in_flight ? [5, 2] : [3, 1]
        x_range = (sampled.x.round - x_radius)..(sampled.x.round + x_radius)
        y_range = (sampled.y.round - y_radius)..(sampled.y.round + y_radius)
        query_x_range = [x_range.begin, 0].max..[x_range.end, zone.width - 1].min
        query_y_range = [y_range.begin, 0].max..[y_range.end, zone.height - 1].min
        templates = MapTileTemplate.where(zone: zone.name, x: query_x_range, y: query_y_range).index_by { |tile| [tile.x, tile.y] }
        tiles = y_range.map do |y|
          x_range.map do |x|
            tile = templates[[x, y]]
            in_bounds = x.between?(0, zone.width - 1) && y.between?(0, zone.height - 1)
            Tile.new(x:, y:, terrain_type: in_bounds ? (tile&.terrain_type || "outdoor") : "void", art: tile&.cell_art_presentation)
          end
        end
        velocity_x, velocity_y, motion_ends_at = map_motion(journey, now)
        Map.new(zone:, center_x: sampled.x, center_y: sampled.y, columns: x_radius * 2 + 1, rows: y_radius * 2 + 1,
          tiles:, velocity_x:, velocity_y:, motion_ends_at:)
      end

      def map_motion(journey, now)
        return [0, 0, journey.departs_at] if journey.phase(at: now) == :waiting
        return [0, 0, nil] unless journey.phase(at: now) == :in_flight

        elapsed = now - journey.departs_at
        index = journey.waypoints.rindex { |point| point.fetch("offset_seconds") <= elapsed }
        point, following = journey.waypoints[index, 2]
        deadline = journey.departs_at + following.fetch("offset_seconds")
        return [0, 0, deadline] unless point.fetch("zone_id") == following.fetch("zone_id")

        seconds = following.fetch("offset_seconds") - point.fetch("offset_seconds")
        [(following.fetch("x") - point.fetch("x")) / seconds.to_f,
          (following.fetch("y") - point.fetch("y")) / seconds.to_f, deadline]
      end
    end
  end
end
