# frozen_string_literal: true

# TileResource tracks resource spawns at specific map tiles.
# Resources respawn after a cooldown period (default 30 minutes).
# Different biomes spawn different resource types.
#
# Usage:
#   TileResource.at_tile(zone_name, x, y) # Find resource at tile
#   TileResource.available                 # Resources ready to harvest
#   resource.harvest!(character)           # Harvest and start respawn timer
#
class TileResource < ApplicationRecord
  RESPAWN_SECONDS = 30.minutes.to_i
  RESOURCE_TYPES = %w[ore wood herb fish crystal gem].freeze

  belongs_to :harvested_by, class_name: "Character", optional: true

  validates :zone, :x, :y, :resource_key, presence: true
  validates :resource_type, inclusion: {in: RESOURCE_TYPES}
  validates :quantity, :base_quantity, numericality: {greater_than_or_equal_to: 0}

  scope :in_zone, ->(zone_name) { where(zone: zone_name) }

  # Find resource at specific tile coordinates (returns single record or nil)
  def self.at_tile(zone, x, y)
    find_by(zone: zone, x: x, y: y)
  end
  scope :available, -> { where("respawns_at IS NULL OR respawns_at <= ?", Time.current).where("quantity > 0") }
  scope :depleted, -> { where(quantity: 0).or(where("respawns_at > ?", Time.current)) }
  scope :needs_respawn, -> { where("respawns_at IS NOT NULL AND respawns_at <= ?", Time.current).where(quantity: 0) }

  # Check if resource is available for harvesting
  def available?
    quantity.positive? && (respawns_at.nil? || respawns_at <= Time.current)
  end

  # Check if resource is depleted and waiting for respawn
  def depleted?
    quantity.zero? || (respawns_at.present? && respawns_at > Time.current)
  end

  # Time until respawn (for display)
  def time_until_respawn
    return 0 if available?
    return 0 if respawns_at.nil?

    [(respawns_at - Time.current).to_i, 0].max
  end

  # Harvest the resource, returns quantity harvested
  def harvest!(character, amount: 1)
    return 0 unless available?

    harvested = [amount, quantity].min
    new_quantity = quantity - harvested

    update!(
      quantity: new_quantity,
      last_harvested_at: Time.current,
      harvested_by: character,
      respawns_at: new_quantity.zero? ? Time.current + respawn_duration : respawns_at
    )

    # Schedule respawn job if depleted
    TileResourceRespawnJob.set(wait: respawn_duration).perform_later(id) if new_quantity.zero?

    harvested
  end

  # Respawn the resource with a new random resource from the biome
  def respawn!
    new_resource = Game::World::BiomeResourceConfig.sample_resource(biome || "plains")

    update!(
      resource_key: new_resource[:key],
      resource_type: new_resource[:type],
      quantity: new_resource[:quantity] || 1,
      base_quantity: new_resource[:quantity] || 1,
      respawns_at: nil,
      harvested_by: nil,
      metadata: new_resource[:metadata] || {}
    )
  end

  # Get display name for the resource
  def display_name
    resource_key.titleize
  end

  # Get the item template for this resource (if exists)
  def item_template
    @item_template ||= ItemTemplate.find_by(key: resource_key) ||
      ItemTemplate.find_by(name: display_name)
  end

  private

  def respawn_duration
    base = RESPAWN_SECONDS

    # Biome modifiers
    case biome
    when "forest"
      base -= 5.minutes.to_i # Faster in forests
    when "mountain"
      base += 10.minutes.to_i # Slower in mountains
    when "swamp"
      base -= 2.minutes.to_i
    end

    # Rarity modifiers (from metadata)
    case metadata&.dig("rarity")
    when "rare"
      base += 15.minutes.to_i
    when "epic"
      base += 30.minutes.to_i
    end

    base.clamp(10.minutes.to_i, 2.hours.to_i)
  end
end
