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
  MAX_ENCOUNTER_SIZE = 20
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

  # Personal grinding instances never share a defeat lock — every player may
  # start a fight while the authored placement stays active.
  def personal_instance?
    value = metadata.to_h["personal_instance"]
    return true if value == true || value.to_s == "true"

    metadata.to_h.key?("respawn_seconds") && metadata.to_h["respawn_seconds"].to_i.zero?
  end

  # Check if NPC is alive and interactable.
  # Lazy-respawn when the authored timer elapsed so patrol loops work without a worker.
  # Personal ambush instances must still honor defeated_at / active:false so a
  # finished fight does not leave a sticky yellow name on the outdoor cell.
  def alive?
    if personal_instance?
      return active? && defeated_at.nil?
    end

    maybe_respawn_if_due!
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
    maybe_respawn_if_due!
    defeated_at.present?
  end

  # Time until respawn (for display)
  def time_until_respawn
    maybe_respawn_if_due!
    return 0 if alive?
    return 0 if respawns_at.nil?

    [(respawns_at - Time.current).to_i, 0].max
  end

  # Defeat the NPC, start respawn timer. Personal instances never lock the cell.
  def defeat!(character)
    return false if personal_instance?
    return false unless alive?

    respawn_time = calculate_respawn_time

    update!(
      defeated_at: Time.current,
      defeated_by: character,
      respawns_at: respawn_time ? Time.current + respawn_time : nil,
      current_hp: 0
    )

    TileNpcRespawnJob.set(wait: respawn_time).perform_later(id) if respawn_time&.positive?

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

  def maybe_respawn_if_due!
    return false unless defeated_at.present?
    return false if respawns_at.nil? || respawns_at > Time.current

    respawn!
  end

  # Get display name
  def display_name
    npc_template&.name.presence || I18n.t("manage.views.npc_key_fallback", key: npc_key)
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
  # Personal instances are always repeatable for concurrent farm.
  def repeatable_encounter_source?
    personal_instance? || encounter_roster_samples.any?
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
      errors << I18n.t("manage.active_boolean")
    end
    samples = metadata["encounter_rosters"]
    return errors unless samples.is_a?(Array)

    errors << I18n.t("manage.encounter_rosters_exceed", max: MAX_ROSTER_SAMPLES) if samples.size > MAX_ROSTER_SAMPLES
    samples.grep(Hash).each do |sample|
      weight = sample["weight"]
      if sample.key?("weight") && !(weight.is_a?(Integer) && weight.between?(1, MAX_ROSTER_WEIGHT))
        errors << I18n.t("manage.encounter_roster_weight_range", max: MAX_ROSTER_WEIGHT)
      end
      Array(sample["members"]).grep(Hash).each do |member|
        if member.key?("level")
          level = Integer(member["level"].to_s, exception: false)
          errors << I18n.t("manage.level_non_negative") unless level && level >= 0
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
      errors << I18n.t("manage.encounter_level_range_bounds", max: MAX_AUTHORED_LEVEL)
    end
    errors << I18n.t("manage.encounter_level_or_range") if member.key?("level")
    errors << I18n.t("manage.encounter_level_range_requires_hp") unless member["hp"].is_a?(Integer) && member["hp"].positive?
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
    errors.add(:metadata, I18n.t("manage.encounter_unknown_templates", keys: missing.join(", "))) if missing.any?
  end

  def encounter_size_is_supported
    return if encounter_size.between?(1, MAX_ENCOUNTER_SIZE)

    errors.add(:metadata, I18n.t("manage.encounter_count_range", max: MAX_ENCOUNTER_SIZE))
  end

  def encounter_roster_samples_are_supported
    return unless metadata.to_h.key?("encounter_rosters")

    samples = metadata.to_h["encounter_rosters"]
    unless samples.is_a?(Array) && samples.size.between?(1, MAX_ROSTER_SAMPLES)
      errors.add(:metadata, I18n.t("manage.encounter_rosters_required"))
      return
    end

    sample_keys = samples.filter_map do |raw_sample|
      unless raw_sample.is_a?(Hash)
        errors.add(:metadata, I18n.t("manage.encounter_roster_entry_object"))
        next
      end

      sample = raw_sample.stringify_keys
      validate_roster_members(sample["members"])
      validate_optional_non_negative_integer(sample, "encounter_experience_reward")
      validate_optional_percent(sample, "trauma_percent")
      key = sample["key"].to_s
      errors.add(:metadata, I18n.t("manage.encounter_roster_key_required")) if key.blank?
      key.presence
    end

    if sample_keys.size != sample_keys.uniq.size
      errors.add(:metadata, I18n.t("manage.encounter_roster_keys_unique"))
    end
  end

  def validate_roster_members(raw_members)
    unless raw_members.is_a?(Array) && raw_members.size.between?(1, MAX_ENCOUNTER_SIZE)
      errors.add(:metadata, I18n.t("manage.encounter_roster_members_range", max: MAX_ENCOUNTER_SIZE))
      return
    end

    raw_members.each do |raw_member|
      unless raw_member.is_a?(Hash)
        errors.add(:metadata, I18n.t("manage.encounter_roster_member_object"))
        next
      end

      member = raw_member.stringify_keys
      errors.add(:metadata, I18n.t("manage.encounter_roster_npc_key_required")) if member["npc_key"].blank?
      validate_optional_positive_integer(member, "hp")
      if member.key?("metadata") && !member["metadata"].is_a?(Hash)
        errors.add(:metadata, I18n.t("manage.encounter_roster_member_metadata_object"))
      end
    end
  end

  def passive_delay_windows_are_supported
    return unless metadata.to_h.key?("passive_delay_windows")

    windows = metadata.to_h["passive_delay_windows"]
    unless windows.is_a?(Array) && windows.any?
      errors.add(:metadata, I18n.t("manage.passive_delay_windows_required"))
      return
    end

    windows.each do |raw_window|
      unless raw_window.is_a?(Hash)
        errors.add(:metadata, I18n.t("manage.passive_delay_window_object"))
        next
      end

      window = raw_window.stringify_keys
      minimum = Integer(window["min_seconds"], exception: false)
      maximum = Integer(window["max_seconds"], exception: false)
      unless minimum&.positive? && maximum&.between?(minimum, MAX_PASSIVE_DELAY_SECONDS)
        errors.add(
          :metadata,
          I18n.t("manage.passive_delay_window_bounds", max: MAX_PASSIVE_DELAY_SECONDS)
        )
      end
    end
  end

  def validate_optional_positive_integer(data, key)
    return unless data.key?(key)
    return if Integer(data[key], exception: false)&.positive?

    errors.add(:metadata, I18n.t("manage.positive_integer_field", key: key))
  end

  def validate_optional_non_negative_integer(data, key)
    return unless data.key?(key)
    value = Integer(data[key], exception: false)
    return if value && value >= 0

    errors.add(:metadata, I18n.t("manage.non_negative_integer_field", key: key))
  end

  def validate_optional_percent(data, key)
    return unless data.key?(key)
    return if Integer(data[key], exception: false)&.between?(0, 100)

    errors.add(:metadata, I18n.t("manage.percent_field", key: key))
  end

  def calculate_respawn_time
    seconds = template_respawn_seconds
    return if seconds.nil? || seconds <= 0

    variance_seconds = template_respawn_variance_seconds
    variance = variance_seconds.to_i.positive? ? rand(-variance_seconds..variance_seconds) : 0
    base = seconds + variance

    base.clamp(1, 24.hours.to_i)
  end

  def template_respawn_seconds
    if metadata.to_h.key?("respawn_seconds")
      value = Integer(metadata["respawn_seconds"], exception: false)
      return value if value && value >= 0
    end

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
