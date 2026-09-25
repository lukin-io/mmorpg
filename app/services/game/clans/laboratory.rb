# frozen_string_literal: true

module Game
  module Clans
    # Authoritative Blood III recipe gate from a clan-owned fortress laboratory.
    class Laboratory
      def self.unlocked?(character)
        clan_id = character.clan_membership&.clan_id
        return false unless clan_id

        FortressBuilding
          .joins(:world_fortress)
          .where(world_fortresses: {owner_clan_id: clan_id, active: true})
          .where(building_key: "laboratory")
          .where("fortress_buildings.level >= ?", 1)
          .exists?
      end
    end
  end
end
