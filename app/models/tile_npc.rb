# frozen_string_literal: true

# TileNpc tracks NPC spawns at specific map tiles.
# NPCs respawn after being defeated (~30 minutes +/- 5 minutes randomness).
# Different biomes spawn different NPC types.
#
# Usage:
#   TileNpc.at_tile(zone_name, x, y) # Find NPC at tile
#   TileNpc.alive                     # NPCs ready to interact/fight
#   npc.defeat!(character)            # Mark defeated and start respawn timer
#
class TileNpc < ApplicationRecord
  BASE_RESPAWN_SECONDS = 30.minutes.to_i
  RESPAWN_VARIANCE = 5.minutes.to_i # +/- 5 minutes randomness
  NPC_ROLES = %w[hostile friendly vendor quest_giver trainer guard].freeze

  belongs_to :npc_template
  belongs_to :defeated_by, class_name: "Character", optional: true

  validates :zone, :x, :y, :npc_key, presence: true
  validates :npc_role, inclusion: {in: NPC_ROLES}
  validates :level, numericality: {greater_than: 0}

  scope :in_zone, ->(zone_name) { where(zone: zone_name) }

  # Find NPC at specific tile coordinates (returns single record or nil)
  def self.at_tile(zone, x, y)
    find_by(zone: zone, x: x, y: y)
  end
  scope :alive, -> { where("respawns_at IS NULL OR respawns_at <= ?", Time.current).where(defeated_at: nil) }
  scope :defeated, -> { where.not(defeated_at: nil) }
  scope :needs_respawn, -> { where("respawns_at IS NOT NULL AND respawns_at <= ?", Time.current).where.not(defeated_at: nil) }
  scope :hostile, -> { where(npc_role: "hostile") }
  scope :friendly, -> { where.not(npc_role: "hostile") }

  # Check if NPC is alive and interactable
  def alive?
    defeated_at.nil? && (respawns_at.nil? || respawns_at <= Time.current)
  end

  # Check if NPC is defeated and waiting for respawn
  def defeated?
    defeated_at.present?
  end

  # Time until respawn (for display)
  def time_until_respawn
    return 0 if alive?
    return 0 if respawns_at.nil?

    [(respawns_at - Time.current).to_i, 0].max
  end

  # Defeat the NPC, start respawn timer
  def defeat!(character)
    return false unless alive?

    respawn_time = calculate_respawn_time

    update!(
      defeated_at: Time.current,
      defeated_by: character,
      respawns_at: Time.current + respawn_time,
      current_hp: 0
    )

    # Schedule respawn job
    TileNpcRespawnJob.set(wait: respawn_time).perform_later(id)

    true
  end

  # Respawn the NPC with a new random NPC from the biome
  def respawn!
    new_npc_data = Game::World::BiomeNpcConfig.sample_npc(biome || "plains")
    return unless new_npc_data

    # Find or create NPC template
    template = find_or_create_template(new_npc_data)
    return unless template

    update!(
      npc_template: template,
      npc_key: new_npc_data[:key],
      npc_role: new_npc_data[:role] || "hostile",
      level: calculate_spawn_level(new_npc_data),
      current_hp: template.health,
      max_hp: template.health,
      respawns_at: nil,
      defeated_at: nil,
      defeated_by: nil,
      metadata: new_npc_data[:metadata] || {}
    )
  end

  # Get display name
  def display_name
    npc_template&.name || npc_key.titleize
  end

  # Check if hostile (can be attacked)
  def hostile?
    npc_role == "hostile"
  end

  # Check if friendly (can interact)
  def friendly?
    !hostile?
  end

  # HP percentage for display
  def hp_percentage
    return 100 if max_hp.nil? || max_hp.zero?

    ((current_hp.to_f / max_hp) * 100).round
  end

  private

  def calculate_respawn_time
    # Base 30 min +/- 5 min random variance
    variance = rand(-RESPAWN_VARIANCE..RESPAWN_VARIANCE)
    base = BASE_RESPAWN_SECONDS + variance

    # Biome modifiers
    case biome
    when "forest"
      base -= 3.minutes.to_i # Faster in forests (wildlife)
    when "mountain"
      base += 5.minutes.to_i # Slower in mountains
    when "swamp"
      base -= 2.minutes.to_i # Faster in swamps
    end

    # Rarity modifiers
    case metadata&.dig("rarity")
    when "rare"
      base += 10.minutes.to_i
    when "elite"
      base += 20.minutes.to_i
    when "boss"
      base += 60.minutes.to_i
    end

    base.clamp(10.minutes.to_i, 3.hours.to_i)
  end

  def calculate_spawn_level(npc_data)
    base_level = npc_data[:level] || 1
    variance = npc_data[:level_variance] || 2

    (base_level + rand(-variance..variance)).clamp(1, 100)
  end

  def find_or_create_template(npc_data)
    # Try to find existing template
    template = NpcTemplate.find_by(npc_key: npc_data[:key])
    return template if template

    # Create new template
    NpcTemplate.create!(
      npc_key: npc_data[:key],
      name: npc_data[:name],
      role: npc_data[:role] || "hostile",
      level: npc_data[:level] || 1,
      dialogue: npc_data[:dialogue] || "...",
      metadata: {
        biome: biome,
        health: npc_data[:hp] || 100,
        base_damage: npc_data[:damage] || 10,
        xp_reward: npc_data[:xp] || 10,
        loot_table: npc_data[:loot] || []
      }.merge(npc_data[:metadata] || {})
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create NPC template for #{npc_data[:key]}: #{e.message}")
    nil
  end
end
