# frozen_string_literal: true

# TileNpc tracks NPCs materialized at captured source-backed map tiles.
# Template metadata may define observed respawn timing; otherwise a defeated
# NPC remains defeated until a source-backed timing rule exists.
#
# Usage:
#   TileNpc.at_tile(zone_name, x, y) # Find NPC at tile
#   TileNpc.alive                     # NPCs ready to interact/fight
#   npc.defeat!(character)            # Mark defeated and start respawn timer
#
class TileNpc < ApplicationRecord
  NPC_ROLES = %w[hostile].freeze
  MAX_ENCOUNTER_SIZE = 8

  belongs_to :npc_template
  belongs_to :defeated_by, class_name: "Character", optional: true

  validates :zone, :x, :y, :npc_key, presence: true
  validates :npc_role, inclusion: {in: NPC_ROLES}
  validates :level, numericality: {greater_than: 0}
  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :x, uniqueness: {scope: [:zone, :y]}
  validates :current_hp, :max_hp, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validate :encounter_size_is_supported

  scope :in_zone, ->(zone_name) { where(zone: zone_name) }

  # Find NPC at specific tile coordinates (returns single record or nil)
  def self.at_tile(zone, x, y)
    find_by(zone: zone, x: x, y: y)
  end
  scope :alive, -> { where("respawns_at IS NULL OR respawns_at <= ?", Time.current).where(defeated_at: nil) }
  scope :defeated, -> { where.not(defeated_at: nil) }
  scope :needs_respawn, -> { where("respawns_at IS NOT NULL AND respawns_at <= ?", Time.current).where.not(defeated_at: nil) }
  scope :hostile, -> { where(npc_role: "hostile") }

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
      respawns_at: respawn_time ? Time.current + respawn_time : nil,
      current_hp: 0
    )

    TileNpcRespawnJob.set(wait: respawn_time).perform_later(id) if respawn_time

    true
  end

  # Respawn the same persisted NPC placement from its explicit template.
  def respawn!
    update!(
      current_hp: max_hp.presence || npc_template.health,
      respawns_at: nil,
      defeated_at: nil,
      defeated_by: nil
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

  # One materialized tile NPC is the encounter anchor. Neverlands can place
  # several copies of that source NPC on the same combat side, so the explicit
  # source metadata controls how many fight participations the anchor creates.
  def encounter_size
    value = Integer(metadata.to_h.fetch("encounter_count", 1), exception: false)
    value || 0
  end

  # HP percentage for display
  def hp_percentage
    return 100 if max_hp.nil? || max_hp.zero?

    ((current_hp.to_f / max_hp) * 100).round
  end

  private

  def encounter_size_is_supported
    return if encounter_size.between?(1, MAX_ENCOUNTER_SIZE)

    errors.add(:metadata, "encounter count must be between 1 and #{MAX_ENCOUNTER_SIZE}")
  end

  def calculate_respawn_time
    return unless template_respawn_seconds

    variance_seconds = template_respawn_variance_seconds
    variance = variance_seconds.to_i.positive? ? rand(-variance_seconds..variance_seconds) : 0
    base = template_respawn_seconds + variance

    base.clamp(1, 24.hours.to_i)
  end

  def template_respawn_seconds
    metadata_respawn_seconds ||
      npc_template&.respawn_seconds
  end

  def template_respawn_variance_seconds
    metadata_respawn_variance_seconds ||
      npc_template&.respawn_variance_seconds ||
      0
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
