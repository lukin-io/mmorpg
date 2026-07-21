# frozen_string_literal: true

# MapTileTemplate defines explicit source-backed tile display/passability data.
# Note: `zone` is stored as a string (zone name), not a foreign key.
class MapTileTemplate < ApplicationRecord
  TERRAIN_TYPES = %w[outdoor].freeze

  LOCAL_ACTION_DEFINITIONS = {
    "resource_search" => {
      "source_id" => "look",
      "world_action_type" => "search_resources",
      "implemented" => true,
      "default_label" => "Look Around",
      "default_message" => "You search the surroundings for herbs and local resources."
    },
    "fishing" => {
      "source_id" => "fis",
      "world_action_type" => "fish",
      "implemented" => false,
      "default_label" => "Fish"
    },
    "drinking" => {
      "source_id" => "dri",
      "world_action_type" => "drink",
      "implemented" => false,
      "default_label" => "Drink"
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
  validates :terrain_type, presence: true
  validates :terrain_type, inclusion: {in: TERRAIN_TYPES}
  validate :zone_must_be_string
  validate :local_actions_must_be_source_backed

  # Custom setter to ensure zone is always stored as a string name
  def zone=(value)
    super(value.is_a?(Zone) ? value.name : value)
  end

  private

  def zone_must_be_string
    if zone.present? && zone.to_s.start_with?("#<Zone:")
      errors.add(:zone, "must be a zone name string, not a Zone object")
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

  def local_actions
    Array(metadata&.dig("local_actions")).filter_map do |action|
      action.deep_stringify_keys if action.respond_to?(:deep_stringify_keys)
    end
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

  def self.default_local_action_label(action_type)
    local_action_definition(action_type)&.fetch("default_label", nil)
  end

  def self.local_action_implemented?(action_type)
    local_action_definition(action_type)&.fetch("implemented", false) == true
  end

  def self.default_local_action_message(action_type)
    local_action_definition(action_type)&.fetch("default_message", nil)
  end

  def self.source_action_id_for(action_type)
    local_action_definition(action_type)&.fetch("source_id", nil)
  end

  private

  def local_actions_must_be_source_backed
    raw_actions = metadata&.dig("local_actions")
    return if raw_actions.nil?

    unless raw_actions.is_a?(Array)
      errors.add(:metadata, "local_actions must be an array")
      return
    end

    normalized_actions = raw_actions.filter_map do |action|
      unless action.respond_to?(:deep_stringify_keys)
        errors.add(:metadata, "local action must be an object")
        next
      end

      action.deep_stringify_keys
    end

    normalized_actions.each do |action|
      definition = self.class.local_action_definition(action["type"])
      unless definition
        errors.add(:metadata, "contains unsupported local action type #{action['type'].inspect}")
        next
      end

      unless action["source_id"] == definition.fetch("source_id")
        errors.add(:metadata, "local action #{action['type']} must use source id #{definition.fetch('source_id')}")
      end
    end

    duplicate_types = normalized_actions.map { |action| action["type"] }.compact.tally.select { |_, count| count > 1 }.keys
    errors.add(:metadata, "contains duplicate local action types: #{duplicate_types.join(', ')}") if duplicate_types.any?
  end
end
