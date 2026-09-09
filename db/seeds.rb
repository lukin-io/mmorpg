# frozen_string_literal: true

# Explicit dependency order for a repeatable Rails bootstrap. Each phase owns
# its records and resolves its inputs from the database; no shared local scope
# or request-time content materialization is involved. `load` intentionally
# reruns phases when Rails.application.load_seed is called again.
# Outdoor NPC bootstrap follows entrances so it can respect their authored cells.
require_relative "seeds/world_content_support"

%w[
  accounts
  world_zones
  world_cells
  starter_characters
  shop_inventory
  starter_wallets
  arena_rooms
  world_locations
  city_hotspots
  outdoor_npcs
].each do |phase|
  load Rails.root.join("db/seeds", "#{phase}.rb")
end
