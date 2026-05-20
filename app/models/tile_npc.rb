# frozen_string_literal: true

# TileNpc tracks NPC spawns at specific map tiles.
# Template metadata defines spawn timing; tile instances store concrete
# defeated/respawn state.
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
    return false unless new_npc_data

    # Find or create NPC template
    template = find_or_create_template(new_npc_data)
    return false unless template

    update!(
      npc_template: template,
      npc_key: new_npc_data[:key].to_s,
      npc_role: (new_npc_data[:role] || "hostile").to_s,
      level: calculate_spawn_level(new_npc_data),
      current_hp: template.health,
      max_hp: template.health,
      respawns_at: nil,
      defeated_at: nil,
      defeated_by: nil,
      metadata: new_npc_data[:metadata] || {}
    )
    true
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
    variance_seconds = template_respawn_variance_seconds
    variance = variance_seconds.positive? ? rand(-variance_seconds..variance_seconds) : 0
    base = template_respawn_seconds + variance
    base += Game::World::BiomeNpcConfig.respawn_modifier(biome || "plains").to_i

    # Rarity modifiers
    case spawn_rarity
    when "rare"
      base += 10.minutes.to_i
    when "elite"
      base += 20.minutes.to_i
    when "boss"
      base += 60.minutes.to_i
    end

    base.clamp(1, 24.hours.to_i)
  end

  def template_respawn_seconds
    metadata_respawn_seconds ||
      npc_template&.respawn_seconds ||
      BASE_RESPAWN_SECONDS
  end

  def template_respawn_variance_seconds
    metadata_respawn_variance_seconds ||
      npc_template&.respawn_variance_seconds ||
      RESPAWN_VARIANCE
  end

  def metadata_respawn_seconds
    positive_metadata_integer("respawn_seconds") ||
      positive_metadata_integer("spawn_respawn_seconds")
  end

  def metadata_respawn_variance_seconds
    value = metadata_integer("respawn_variance_seconds") ||
      metadata_integer("spawn_respawn_variance_seconds")
    value if value && value >= 0
  end

  def spawn_rarity
    metadata&.dig("spawn_rarity").presence ||
      metadata&.dig("rarity").presence ||
      npc_template&.spawn_rarity
  end

  def calculate_spawn_level(npc_data)
    base_level = npc_data[:level] || 1
    variance = npc_data[:level_variance] || 2

    (base_level + rand(-variance..variance)).clamp(1, 100)
  end

  def find_or_create_template(npc_data)
    # Normalize key to string for consistent lookups
    npc_key = npc_data[:key].to_s
    npc_name = npc_data[:name].to_s

    # Try to find existing template by npc_key first, then by name
    template = NpcTemplate.find_by(npc_key: npc_key) ||
      NpcTemplate.find_by(name: npc_name)

    if template
      # Update npc_key if missing (for templates created by factory)
      template.update!(npc_key: npc_key) if template.npc_key.blank?
      sync_template_spawn_metadata(template, npc_data)
      return template
    end

    # Create new template with retry for race condition handling
    create_npc_template_with_retry(npc_key, npc_name, npc_data)
  end

  def create_npc_template_with_retry(npc_key, npc_name, npc_data, retries: 3)
    NpcTemplate.create!(
      npc_key: npc_key,
      name: npc_name,
      role: npc_data[:role]&.to_s || "hostile",
      level: npc_data[:level] || 1,
      dialogue: npc_data[:dialogue]&.to_s || "...",
      metadata: template_spawn_metadata(npc_data)
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("NPC template creation conflict for #{npc_key}: #{e.message}")

    # Try to find existing template (race condition: another process created it)
    template = NpcTemplate.find_by(npc_key: npc_key) || NpcTemplate.find_by(name: npc_name)
    return template if template

    # Retry with backoff if template not found yet (transaction not committed)
    if retries > 0
      sleep(0.05 * (4 - retries)) # 50ms, 100ms, 150ms backoff
      return create_npc_template_with_retry(npc_key, npc_name, npc_data, retries: retries - 1)
    end

    Rails.logger.error("Failed to find or create NPC template for #{npc_key} after retries")
    nil
  end

  def sync_template_spawn_metadata(template, npc_data)
    additions = template_spawn_metadata(npc_data).compact
    missing = additions.except(*template.metadata.keys)
    return if missing.empty?

    template.update!(metadata: template.metadata.merge(missing))
  end

  def template_spawn_metadata(npc_data)
    {
      "biome" => biome,
      "health" => npc_data[:hp] || 100,
      "base_damage" => npc_data[:damage] || 10,
      "xp_reward" => npc_data[:xp] || 10,
      "loot_table" => npc_data[:loot] || [],
      "spawn_chance" => npc_data[:spawn_chance],
      "respawn_seconds" => npc_data[:respawn_seconds],
      "respawn_variance_seconds" => npc_data[:respawn_variance_seconds]
    }.merge((npc_data[:metadata] || {}).deep_stringify_keys)
  end

  def positive_metadata_integer(key)
    value = metadata_integer(key)
    value if value&.positive?
  end

  def metadata_integer(key)
    value = metadata&.dig(key)
    return if value.blank?

    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end
end
