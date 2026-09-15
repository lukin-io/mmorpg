# frozen_string_literal: true

module Game
  module Shop
    # Resolves a character's accessible Shop building and its independent
    # economy account. The fingerprint binds offers to authored access state;
    # changes to funds or stock do not invalidate unrelated customer quotes.
    class Location
      Result = Data.define(:building, :fingerprint, :account)

      def initialize(character:)
        @character = character
      end

      def call
        context = Game::World::ResumeContext.new(character:)
        position = character.position&.reload
        hospital = character.gameplay_context.dig("params", "building_key") == "hospital" &&
          character.gameplay_context["name"] == "city_building" &&
          Game::World::CityBuildingCatalog.accessible?(character:, building_key: "hospital")
        unless ((character.gameplay_context["name"] == "shop" && context.shop_available?) || hospital) && position&.active? && !MovementCommand.moving.where(character:).exists? &&
            !Game::World::LocalActionState.new(character:).call &&
            !character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
          raise TradeOffers::Unavailable, "Shop is only available from an accessible trading location."
        end

        building = context.shop_parent_location
        type = building ? "village" : "city"
        building ||= CityHotspot.for_zone(position.zone).detect do |candidate|
          candidate.action_params.to_h["feature"] == (hospital ? "hospital" : "shop") && candidate.can_interact?(character)
        end
        raise TradeOffers::Unavailable, "Shop is no longer available." unless building

        Result.new(
          building:,
          fingerprint: {"type" => type, "id" => building.id, "revision" => building.updated_at.iso8601(6)},
          account: ShopAccount.find_by(location: building)
        )
      end

      private

      attr_reader :character
    end
  end
end
