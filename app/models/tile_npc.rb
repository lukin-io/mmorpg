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
  MAX_ENCOUNTER_SIZE = 10
  MAX_ROSTER_SAMPLES = 64
  MAX_ROSTER_WEIGHT = 10_000
  MAX_AUTHORED_LEVEL = 1_000
  MAX_PASSIVE_DELAY_SECONDS = 24.hours.to_i

  belongs_to :npc_template
  belongs_to :defeated_by, class_name: "Character", optional: true

  validates :zone, :x, :y, :npc_key, presence: true
  validates :npc_role, inclusion: {in: NPC_ROLES}
  validates :level, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :x, uniqueness: {scope: [:zone, :y]}
  validates :current_hp, :max_hp, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validate :encounter_size_is_supported
  validate :encounter_roster_samples_are_supported
  validate :passive_delay_windows_are_supported
  validate :encounter_policy_is_supported
  validate :encounter_templates_must_exist

  scope :in_zone, ->(zone_name) { where(zone: zone_name) }
  scope :active, -> { where("metadata->'active' IS NULL OR metadata->'active' = 'true'::jsonb") }

  # Find NPC at specific tile coordinates (returns single record or nil)
  def self.at_tile(zone, x, y)
    find_by(zone: zone, x: x, y: y)
  end
  scope :alive, -> { active.where("respawns_at IS NULL OR respawns_at <= ?", Time.current).where(defeated_at: nil) }
  scope :defeated, -> { where.not(defeated_at: nil) }
  scope :needs_respawn, -> { where("respawns_at IS NOT NULL AND respawns_at <= ?", Time.current).where.not(defeated_at: nil) }
  scope :hostile, -> { where(npc_role: "hostile") }

  # Check if NPC is alive and interactable
  def alive?
    active? && defeated_at.nil? && (respawns_at.nil? || respawns_at <= Time.current)
  end

  # Deactivation preserves the authored roster and its defeat/respawn state.
  def active?
    !metadata.to_h.key?("active") || metadata["active"] == true
  end

  alias_method :active, :active?

  def active=(value)
    self.metadata = metadata.to_h.merge("active" => ActiveModel::Type::Boolean.new.cast(value))
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

  # Captured complete roster outputs for this exact cell. Each entry is one
  # observed source result, not a claim about the source's hidden weights.
  def encounter_roster_samples
    value = metadata.to_h["encounter_rosters"]
    value.is_a?(Array) ? value : []
  end

  # Authored captured or user-reported timing for passive attacks on this cell.
  # The runtime samples only inside these explicit bounds when they exist.
  def passive_delay_windows
    value = metadata.to_h["passive_delay_windows"]
    value.is_a?(Array) ? value : []
  end

  # A sampled cell represents a repeatable Neverlands encounter source, not
  # one killable NPC instance. Completing one sampled roster therefore leaves
  # the cell eligible to schedule another independently selected encounter.
  def repeatable_encounter_source?
    encounter_roster_samples.any?
  end

  # HP percentage for display
  def hp_percentage
    return 100 if max_hp.nil? || max_hp.zero?

    ((current_hp.to_f / max_hp) * 100).round
  end

  # Pure validation shared by persisted content and the seed catalog. Optional
  # ranges/weights describe authored policy, not inferred Neverlands formulas.
  def self.encounter_policy_errors(metadata)
    errors = []
    if metadata.key?("active") && ![true, false].include?(metadata["active"])
      errors << "active must be true or false"
    end
    samples = metadata["encounter_rosters"]
    return errors unless samples.is_a?(Array)

    errors << "encounter rosters exceed #{MAX_ROSTER_SAMPLES} entries" if samples.size > MAX_ROSTER_SAMPLES
    samples.grep(Hash).each do |sample|
      weight = sample["weight"]
      if sample.key?("weight") && !(weight.is_a?(Integer) && weight.between?(1, MAX_ROSTER_WEIGHT))
        errors << "encounter roster weight must be between 1 and #{MAX_ROSTER_WEIGHT}"
      end
      Array(sample["members"]).grep(Hash).each do |member|
        if member.key?("level")
          level = Integer(member["level"].to_s, exception: false)
          errors << "level must be a non-negative integer" unless level && level >= 0
        end
        errors.concat(member_level_range_errors(member))
      end
    end
    errors.uniq
  end

  def self.member_level_range_errors(member)
    return [] unless member.key?("level_min") || member.key?("level_max")

    errors = []
    minimum = member["level_min"]
    maximum = member["level_max"]
    unless minimum.is_a?(Integer) && maximum.is_a?(Integer) &&
        minimum.between?(0, MAX_AUTHORED_LEVEL) && maximum.between?(minimum, MAX_AUTHORED_LEVEL)
      errors << "encounter roster level range must have ordered bounds between 0 and #{MAX_AUTHORED_LEVEL}"
    end
    errors << "encounter roster member must use either level or level range" if member.key?("level")
    errors << "encounter roster level range requires explicit hp" unless member["hp"].is_a?(Integer) && member["hp"].positive?
    errors
  end

  private

  def encounter_policy_is_supported
    self.class.encounter_policy_errors(metadata.to_h).each { |message| errors.add(:metadata, message) }
  end

  def encounter_templates_must_exist
    return if encounter_roster_samples.empty? || encounter_roster_samples.size > MAX_ROSTER_SAMPLES
    return if persisted? && metadata_in_database.to_h["encounter_rosters"] == metadata.to_h["encounter_rosters"]

    keys = encounter_roster_samples.grep(Hash).flat_map do |sample|
      Array(sample["members"]).first(MAX_ENCOUNTER_SIZE).grep(Hash).filter_map { |member| member["npc_key"].presence }
    end.uniq
    missing = keys - NpcTemplate.where(npc_key: keys).order(:id).lock("FOR KEY SHARE").pluck(:npc_key)
    errors.add(:metadata, "encounter roster references unknown NPC templates: #{missing.join(', ')}") if missing.any?
  end

  def encounter_size_is_supported
    return if encounter_size.between?(1, MAX_ENCOUNTER_SIZE)

    errors.add(:metadata, "encounter count must be between 1 and #{MAX_ENCOUNTER_SIZE}")
  end

  def encounter_roster_samples_are_supported
    return unless metadata.to_h.key?("encounter_rosters")

    samples = metadata.to_h["encounter_rosters"]
    unless samples.is_a?(Array) && samples.size.between?(1, MAX_ROSTER_SAMPLES)
      errors.add(:metadata, "encounter rosters must be a non-empty array")
      return
    end

    sample_keys = samples.filter_map do |raw_sample|
      unless raw_sample.is_a?(Hash)
        errors.add(:metadata, "encounter roster entries must be objects")
        next
      end

      sample = raw_sample.stringify_keys
      validate_roster_members(sample["members"])
      validate_optional_non_negative_integer(sample, "encounter_experience_reward")
      validate_optional_non_negative_integer(sample, "encounter_defeat_experience_reward")
      validate_optional_percent(sample, "trauma_percent")
      key = sample["key"].to_s
      errors.add(:metadata, "encounter roster key is required") if key.blank?
      key.presence
    end

    if sample_keys.size != sample_keys.uniq.size
      errors.add(:metadata, "encounter roster keys must be unique")
    end
  end

  def validate_roster_members(raw_members)
    unless raw_members.is_a?(Array) && raw_members.size.between?(1, MAX_ENCOUNTER_SIZE)
      errors.add(:metadata, "encounter roster members must contain between 1 and #{MAX_ENCOUNTER_SIZE} entries")
      return
    end

    raw_members.each do |raw_member|
      unless raw_member.is_a?(Hash)
        errors.add(:metadata, "encounter roster members must be objects")
        next
      end

      member = raw_member.stringify_keys
      errors.add(:metadata, "encounter roster member npc_key is required") if member["npc_key"].blank?
      validate_optional_positive_integer(member, "hp")
      if member.key?("metadata") && !member["metadata"].is_a?(Hash)
        errors.add(:metadata, "encounter roster member metadata must be an object")
      end
    end
  end

  def passive_delay_windows_are_supported
    return unless metadata.to_h.key?("passive_delay_windows")

    windows = metadata.to_h["passive_delay_windows"]
    unless windows.is_a?(Array) && windows.any?
      errors.add(:metadata, "passive delay windows must be a non-empty array")
      return
    end

    windows.each do |raw_window|
      unless raw_window.is_a?(Hash)
        errors.add(:metadata, "passive delay windows must contain objects")
        next
      end

      window = raw_window.stringify_keys
      minimum = Integer(window["min_seconds"], exception: false)
      maximum = Integer(window["max_seconds"], exception: false)
      unless minimum&.positive? && maximum&.between?(minimum, MAX_PASSIVE_DELAY_SECONDS)
        errors.add(
          :metadata,
          "passive delay window must have positive ordered bounds up to #{MAX_PASSIVE_DELAY_SECONDS} seconds"
        )
      end
    end
  end

  def validate_optional_positive_integer(data, key)
    return unless data.key?(key)
    return if Integer(data[key], exception: false)&.positive?

    errors.add(:metadata, "#{key} must be a positive integer")
  end

  def validate_optional_non_negative_integer(data, key)
    return unless data.key?(key)
    value = Integer(data[key], exception: false)
    return if value && value >= 0

    errors.add(:metadata, "#{key} must be a non-negative integer")
  end

  def validate_optional_percent(data, key)
    return unless data.key?(key)
    return if Integer(data[key], exception: false)&.between?(0, 100)

    errors.add(:metadata, "#{key} must be between 0 and 100")
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
