# frozen_string_literal: true

# MapTileTemplate defines explicit source-backed tile display/passability data.
# Note: `zone` is stored as a string (zone name), not a foreign key.
class MapTileTemplate < ApplicationRecord
  TERRAIN_TYPES = %w[outdoor].freeze
  MAX_RESOURCE_GROUPS = 32
  RESOURCE_KEY_FORMAT = /\A[a-z0-9][a-z0-9_-]{0,79}\z/

  LOCAL_ACTION_DEFINITIONS = {
    "resource_search" => {
      "source_id" => "look",
      "world_action_type" => "search_resources",
      "implemented" => true,
      "default_label" => "Look Around",
      "default_description" => "Search for herbs and local resources.",
      "default_message" => "There is no useful vegetation in this area."
    },
    "fishing" => {
      "source_id" => "fis",
      "world_action_type" => "fish",
      "implemented" => true,
      "default_label" => "Fish",
      "default_message" => "No bait available."
    },
    "drinking" => {
      "source_id" => "dri",
      "world_action_type" => "drink",
      "implemented" => true,
      "default_label" => "Drink",
      "default_message" => "Everything went well."
    },
    "digging" => {
      "source_id" => "dig",
      "world_action_type" => "dig",
      "implemented" => false,
      "default_label" => "Dig"
    }
  }.freeze

  validates :zone, presence: true
  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :x, uniqueness: {scope: [:zone, :y]}
  validates :terrain_type, presence: true
  validates :terrain_type, inclusion: {in: TERRAIN_TYPES}
  validate :zone_must_be_string
  validate :cell_art_must_be_source_backed
  validate :local_actions_must_be_source_backed
  validate :coordinates_must_fit_known_zone
  validate :resource_groups_must_be_valid
  validate :presence_label_must_be_valid

  # Custom setter to ensure zone is always stored as a string name
  def zone=(value)
    super(value.is_a?(Zone) ? value.name : value)
  end

  private

  def zone_must_be_string
    if zone.present? && zone.to_s.start_with?("#<Zone:")
      errors.add(:zone, I18n.t("manage.zone_must_be_name"))
    end
  end

  public

  scope :in_zone, ->(zone_or_name) {
    name = zone_or_name.is_a?(Zone) ? zone_or_name.name : zone_or_name
    where(zone: name)
  }
  scope :in_area, ->(x_range, y_range) { where(x: x_range, y: y_range) }
  scope :passable_only, -> { where(passable: true) }

  # Alias for view compatibility
  def walkable
    passable
  end

  def blocked?
    !passable || metadata&.dig("blocked")
  end

  def cell_art
    raw_cell_art = metadata&.dig("cell_art")
    return unless raw_cell_art.respond_to?(:deep_stringify_keys)

    raw_cell_art.deep_stringify_keys
  end

  def cell_art_presentation
    Game::World::CellArtCatalog.resolve(cell_art)
  end

  def presence_label
    label = metadata.to_h["presence_label"]
    label if label.is_a?(String) && label.present? && label.length <= 120
  end

  def local_actions
    Array(metadata&.dig("local_actions")).filter_map do |action|
      action.deep_stringify_keys if action.respond_to?(:deep_stringify_keys)
    end
  end

  # Authored resource/group identities are independent from action outcomes.
  # A group number is neither a yield, a quantity nor a skill requirement.
  def resource_groups
    value = metadata.to_h["resource_groups"]
    value.is_a?(Array) ? value.select { |entry| entry.is_a?(Hash) } : []
  end

  def active_resource_groups
    resource_groups.reject { |entry| entry["active"] == false }
  end

  def active_local_actions
    local_actions.reject { |action| action["active"] == false }
  end

  def local_action(action_type)
    active_local_actions.find { |action| action["type"] == action_type.to_s }
  end

  def self.local_action_definition(action_type)
    LOCAL_ACTION_DEFINITIONS[action_type.to_s]
  end

  def self.world_action_type_for(action_type)
    local_action_definition(action_type)&.fetch("world_action_type", nil)
  end

  def self.local_action_type_for_world_action(world_action_type)
    key = world_action_type.to_s
    LOCAL_ACTION_DEFINITIONS.each do |action_type, definition|
      return action_type if definition["world_action_type"] == key
    end
    nil
  end

  def self.default_local_action_label(action_type)
    definition = local_action_definition(action_type)
    return unless definition

    I18n.t(
      "game.world.local_action.#{action_type}.label",
      default: definition.fetch("default_label")
    )
  end

  def self.local_action_implemented?(action_type)
    local_action_definition(action_type)&.fetch("implemented", false) == true
  end

  def self.default_local_action_message(action_type)
    definition = local_action_definition(action_type)
    return unless definition

    english_default = definition["default_message"]
    return unless english_default

    I18n.t(
      "game.world.local_action.#{action_type}.message",
      default: english_default
    )
  end

  # Prefer i18n for the structural English defaults while preserving custom manage labels.
  def self.player_local_action_label(action_type, stored_label = nil)
    definition = local_action_definition(action_type)
    return stored_label.presence unless definition

    english_default = definition.fetch("default_label")
    return stored_label if stored_label.present? && stored_label != english_default

    default_local_action_label(action_type)
  end

  # Prefer i18n for structural English descriptions while preserving custom manage copy.
  def self.player_local_action_description(action_type, stored_description = nil)
    definition = local_action_definition(action_type)
    known = translate_known_description(stored_description)
    return known if known != stored_description

    return stored_description.presence unless definition

    english_default = definition["default_description"]
    return stored_description if stored_description.present? && stored_description != english_default

    return stored_description.presence if english_default.blank?

    I18n.t(
      "game.world.local_action.#{action_type}.description",
      default: english_default
    )
  end

  def self.player_local_action_message(action_type, stored_message = nil)
    definition = local_action_definition(action_type)
    return translate_known_result_message(stored_message) if definition.nil?

    english_default = definition["default_message"]
    if stored_message.present? && stored_message != english_default
      return translate_known_result_message(stored_message)
    end

    default_local_action_message(action_type).presence || translate_known_result_message(stored_message)
  end

  KNOWN_RESULT_MESSAGES = {
    "Nothing found." => "game.world.local_action.resource_search.nothing_found",
    "Nothing was found." => "game.world.local_action.resource_search.nothing_found",
    "Nothing useful here." => "game.world.local_action.resource_search.message",
    "No vegetation." => "game.world.local_action.resource_search.message",
    "There is no useful vegetation in this area." => "game.world.local_action.resource_search.message",
    "No bait available." => "game.world.local_action.fishing.message",
    "Everything went well." => "game.world.local_action.drinking.message"
  }.freeze

  KNOWN_DESCRIPTIONS = {
    "Search for herbs and local resources." => "game.world.local_action.resource_search.description",
    "Search this cell for herbs or local resources." => "game.world.local_action.resource_search.description"
  }.freeze

  def self.translate_known_result_message(message)
    return message if message.blank?

    key = KNOWN_RESULT_MESSAGES[message]
    return message unless key

    I18n.t(key, default: message)
  end
  private_class_method :translate_known_result_message

  def self.translate_known_description(description)
    return description if description.blank?

    key = KNOWN_DESCRIPTIONS[description]
    return description unless key

    I18n.t(key, default: description)
  end
  private_class_method :translate_known_description

  def self.source_action_id_for(action_type)
    local_action_definition(action_type)&.fetch("source_id", nil)
  end

  private

  def presence_label_must_be_valid
    return unless metadata.to_h.key?("presence_label")
    return if presence_label

    errors.add(:metadata, I18n.t("manage.presence_label_length"))
  end

  def cell_art_must_be_source_backed
    raw_cell_art = metadata&.dig("cell_art")
    return if raw_cell_art.nil?

    unless raw_cell_art.respond_to?(:to_h)
      errors.add(:metadata, I18n.t("manage.cell_art_object"))
      return
    end

    unless metadata&.dig("source_map").present?
      errors.add(:metadata, I18n.t("manage.cell_art_requires_source_map"))
    end

    unless Game::World::CellArtCatalog.valid_reference?(raw_cell_art)
      errors.add(:metadata, I18n.t("manage.cell_art_slice_invalid"))
    end
  end

  def local_actions_must_be_source_backed
    raw_actions = metadata&.dig("local_actions")
    return if raw_actions.nil?

    unless raw_actions.is_a?(Array)
      errors.add(:metadata, I18n.t("manage.local_actions_array"))
      return
    end

    normalized_actions = raw_actions.filter_map do |action|
      unless action.respond_to?(:deep_stringify_keys)
        errors.add(:metadata, I18n.t("manage.local_action_object"))
        next
      end

      action.deep_stringify_keys
    end

    normalized_actions.each do |action|
      definition = self.class.local_action_definition(action["type"])
      unless definition
        errors.add(:metadata, I18n.t("manage.local_action_unsupported", type: action["type"].inspect))
        next
      end

      unless action["source_id"] == definition.fetch("source_id")
        errors.add(
          :metadata,
          I18n.t(
            "manage.local_action_source_id",
            type: action["type"],
            source_id: definition.fetch("source_id")
          )
        )
      end
      if action.key?("active") && ![true, false].include?(action["active"])
        errors.add(:metadata, I18n.t("manage.local_action_active_boolean"))
      end
    end

    duplicate_types = normalized_actions.map { |action| action["type"] }.compact.tally.select { |_, count| count > 1 }.keys
    if duplicate_types.any?
      errors.add(:metadata, I18n.t("manage.local_action_duplicate_types", types: duplicate_types.join(", ")))
    end
  end

  def resource_groups_must_be_valid
    value = metadata.to_h["resource_groups"]
    return if value.nil?

    unless value.is_a?(Array) && value.size <= MAX_RESOURCE_GROUPS
      errors.add(:metadata, I18n.t("manage.resource_groups_array_max", max: MAX_RESOURCE_GROUPS))
      return
    end

    value.each do |entry|
      unless entry.is_a?(Hash)
        errors.add(:metadata, I18n.t("manage.resource_group_object"))
        next
      end
      unless entry["key"].is_a?(String) && entry["key"].match?(RESOURCE_KEY_FORMAT)
        errors.add(:metadata, I18n.t("manage.resource_group_key_format"))
      end
      unless entry["kind"].is_a?(String) && entry["kind"].match?(RESOURCE_KEY_FORMAT)
        errors.add(:metadata, I18n.t("manage.resource_group_kind_format"))
      end
      unless entry["label"].is_a?(String) && entry["label"].present? && entry["label"].length <= 120
        errors.add(:metadata, I18n.t("manage.resource_group_label_length"))
      end
      if entry.key?("active") && ![true, false].include?(entry["active"])
        errors.add(:metadata, I18n.t("manage.resource_group_active_boolean"))
      end
    end
    keys = value.filter_map { |entry| entry["key"] if entry.is_a?(Hash) }
    errors.add(:metadata, I18n.t("manage.resource_group_keys_unique")) if keys.uniq.size != keys.size
  end

  def coordinates_must_fit_known_zone
    known_zone = Zone.find_by(name: zone)
    return unless known_zone && x.is_a?(Integer) && y.is_a?(Integer)

    errors.add(:x, I18n.t("manage.coord_outside_zone")) unless x < known_zone.width
    errors.add(:y, I18n.t("manage.coord_outside_zone")) unless y < known_zone.height
  end
end
