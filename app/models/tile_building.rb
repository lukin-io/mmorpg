# frozen_string_literal: true

# TileBuilding tracks a captured entrance at a specific outdoor cell.
#
# Usage:
#   TileBuilding.at_tile(zone_name, x, y) # Find building at tile
#   TileBuilding.active                    # Entrances that can be used
#   building.can_enter?(character)         # Check whether the entrance is usable
#   building.enter!(character)             # Move character to its authored node
#
class TileBuilding < ApplicationRecord
  BUILDING_TYPES = %w[city location].freeze
  LOCATION_ACTION_TYPES = %w[open_feature return_world].freeze
  LOCATION_KINDS = %w[village mine exchange].freeze
  IMPLEMENTED_LOCATION_KINDS = LOCATION_KINDS
  LOCATION_KEY_FORMAT = /\A[a-z0-9_-]+\z/

  belongs_to :destination_zone, class_name: "Zone", inverse_of: :destination_tile_buildings, optional: true
  has_one :shop_account, as: :location, dependent: :restrict_with_exception

  validates :zone, :x, :y, :building_key, :name, presence: true
  validates :building_type, inclusion: {in: BUILDING_TYPES}
  validates :building_key, uniqueness: true
  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :x, uniqueness: {scope: [:zone, :y]}
  validates :required_level, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validate :presence_label_must_be_valid
  validate :location_configuration_must_be_valid

  scope :in_zone, ->(zone_name) { where(zone: zone_name) }
  scope :active, -> { where(active: true) }

  # Find building at specific tile coordinates (returns single record or nil)
  #
  # @param zone [String] zone name
  # @param x [Integer] x coordinate
  # @param y [Integer] y coordinate
  # @return [TileBuilding, nil]
  def self.at_tile(zone, x, y)
    find_by(zone: zone, x: x, y: y)
  end

  # Check if the captured entrance has a complete authored destination.
  #
  # @return [Boolean]
  def accessible?
    return false unless active?

    if location?
      IMPLEMENTED_LOCATION_KINDS.include?(location_kind) && location_configuration_errors.empty?
    else
      destination_zone.present? && destination_coordinates_valid?
    end
  end

  # Check if a character can use this entrance.
  #
  # @param character [Character] the character trying to enter
  # @return [Boolean]
  def can_enter?(character)
    entry_blocked_reason(character).nil?
  end

  # Get the reason why a character cannot enter
  #
  # @param character [Character] the character trying to enter
  # @return [String, nil] error message or nil if can enter
  def entry_blocked_reason(character)
    return "Entrance is currently unavailable." unless accessible?
    return "Character is unavailable." unless character&.position
    return "Disembark before entering this location." if character.active_airship_journey
    return "Entrance is not on your current cell." unless on_current_cell?(character.position)

    nil
  end

  # Enter the authored destination. Location interiors preserve the outdoor
  # coordinate; city gates move the character to their persisted city node.
  # Lock the character before the entrance and recheck its exact source region
  # and cell so cached records cannot authorize another region's destination.
  # A changed position and its local-chat entry context persist together.
  #
  # @param character [Character] the character to move
  # @return [Boolean] true if successful
  def enter!(character)
    return false unless character

    character.with_lock do
      with_lock do
        position = character.position&.reload
        next false unless can_enter?(character)

        if location?
          position.touch(:last_action_at)
          Game::World::ResumeContext.new(character:).remember_world_location!(key: location_key)
        else
          position.update!(
            zone: destination_zone,
            x: destination_x,
            y: destination_y,
            last_action_at: Time.current
          )
          Game::World::ResumeContext.new(character:).remember_world!
        end

        true
      end
    end
  end

  def location?
    building_type == "location"
  end

  def location_key
    building_key if location?
  end

  def location_definition
    raw_definition = metadata.to_h["location"]
    return {} unless raw_definition.respond_to?(:deep_stringify_keys)

    raw_definition.deep_stringify_keys
  end

  def location_kind
    location_definition["kind"].to_s
  end

  def location_short_label
    location_definition["short_label"].presence || name
  end

  def presence_label
    metadata.to_h["presence_label"].presence || name
  end

  def location_presence_label
    location_definition["presence_label"].presence || name
  end

  def location_scene
    location_definition.fetch("scene", {}).to_h
  end

  def location_scene_size
    [location_scene["width"].to_i, location_scene["height"].to_i]
  end

  # Lobby sections are read-only presentation within one persisted location.
  # They do not grant shop access, extraction, descent, or exchange operations.
  def location_sections
    Array(location_definition["sections"]).filter_map do |section|
      section.deep_stringify_keys if section.respond_to?(:deep_stringify_keys)
    end
  end

  def location_section(key)
    location_sections.find { |section| section["key"] == key.to_s }
  end

  def location_resource_categories
    Array(location_definition["resource_categories"])
  end

  def location_features
    Array(location_definition["features"]).filter_map do |feature|
      next unless feature.respond_to?(:deep_stringify_keys)

      normalized = feature.deep_stringify_keys
      normalized unless normalized["active"] == false
    end
  end

  def location_feature(key)
    location_features.find { |feature| feature["key"] == key.to_s }
  end

  def location_feature_available?(feature_name)
    location_features.any? do |feature|
      feature["action_type"] == "open_feature" && feature["feature"] == feature_name.to_s
    end
  end

  private

  def on_current_cell?(position)
    position&.zone&.outdoor? && position.zone.name == zone && position.x == x && position.y == y
  end

  def presence_label_must_be_valid
    return unless metadata.to_h.key?("presence_label")

    label = metadata["presence_label"]
    errors.add(:metadata, "presence label must be a non-empty string") unless label.is_a?(String) && label.present?
  end

  def location_configuration_must_be_valid
    return unless location?

    location_configuration_errors.each { |message| errors.add(:metadata, message) }
  end

  def location_configuration_errors
    definition = location_definition
    errors = []
    errors << "location definition is required" if definition.empty?

    kind = definition["kind"].to_s
    errors << "location kind is unsupported" unless LOCATION_KINDS.include?(kind)
    # Managers may keep a planned inactive mine marker before authoring its
    # scene. Activation always requires the complete location contract below.
    return errors if kind == "mine" && !active? && definition["features"].blank?
    if definition.key?("presence_label") && (!definition["presence_label"].is_a?(String) || definition["presence_label"].blank?)
      errors << "location presence label must be a non-empty string"
    end

    width, height = location_scene_size
    errors << "location scene width must be positive" unless width.positive?
    errors << "location scene height must be positive" unless height.positive?
    image = location_scene["image"]
    errors << "location lobby scene image is required" if %w[mine exchange].include?(kind) && image.blank?
    if image.present?
      if !image.is_a?(String) || !image.match?(%r{\Aworld/(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+\.(?:png|jpe?g|webp|gif)\z})
        errors << "location scene image must be a project world asset"
      elsif !Rails.root.join("app/assets/images", image).file?
        errors << "location scene image must exist"
      end
    end
    errors.concat(location_section_errors(definition))

    features = Array(definition["features"])
    errors << "location features must be a non-empty array" unless definition["features"].is_a?(Array) && features.any?
    normalized_features = features.filter_map do |feature|
      unless feature.respond_to?(:deep_stringify_keys)
        errors << "location feature must be an object"
        next
      end

      feature.deep_stringify_keys
    end
    duplicate_keys = normalized_features.pluck("key").compact.tally.select { |_, count| count > 1 }.keys
    errors << "location feature keys must be unique" if duplicate_keys.any?
    normalized_features.each do |feature|
      errors.concat(location_feature_errors(feature, width:, height:))
    end

    errors
  end

  def location_feature_errors(feature, width:, height:)
    errors = []
    key = feature["key"].to_s
    action_type = feature["action_type"].to_s
    errors << "location feature key is invalid" unless key.match?(LOCATION_KEY_FORMAT)
    errors << "location feature label is required" if feature["label"].blank?
    if feature.key?("presence_label") && (!feature["presence_label"].is_a?(String) || feature["presence_label"].blank?)
      errors << "location feature presence label must be a non-empty string"
    end
    errors << "location feature action type is invalid" unless LOCATION_ACTION_TYPES.include?(action_type)
    if action_type == "open_feature" && CityHotspot.feature_route(feature["feature"]).blank?
      errors << "location feature destination is unsupported"
    end
    placement = feature.fetch("placement", "scene")
    errors << "location feature placement is invalid" unless %w[scene navigation].include?(placement)
    unless placement == "navigation" || valid_location_polygon?(feature["polygon"], width:, height:)
      errors << "location feature polygon is invalid"
    end
    errors
  end

  def location_section_errors(definition)
    errors = []
    if definition.key?("sections")
      sections = definition["sections"]
      valid = sections.is_a?(Array) && sections.all? do |section|
        section.is_a?(Hash) && section["key"].to_s.match?(LOCATION_KEY_FORMAT) &&
          section["label"].is_a?(String) && section["label"].present?
      end
      errors << "location sections must have valid keys and labels" unless valid
      errors << "location section keys must be unique" if valid && sections.pluck("key").uniq.size != sections.size
      if valid
        sections.each do |section|
          if section.key?("summary_label") && (!section["summary_label"].is_a?(String) || section["summary_label"].blank?)
            errors << "location section summary label must be a non-empty string"
          end
          next unless section.key?("read_only_items")

          items = section["read_only_items"]
          unless items.is_a?(Array) && items.all? { |item| valid_location_item_preview?(item) }
            errors << "location item previews must have a name and detail labels"
          end
        end
      end
    end
    %w[resource_categories unavailable_actions].each do |key|
      next unless definition.key?(key)

      values = definition[key]
      unless values.is_a?(Array) && values.all? { |value| value.is_a?(String) && value.present? }
        errors << "location #{key} must be an array of labels"
      end
    end
    errors
  end

  def valid_location_item_preview?(item)
    item.is_a?(Hash) && item["name"].is_a?(String) && item["name"].present? &&
      item["details"].is_a?(Array) && item["details"].all? { |detail| detail.is_a?(String) && detail.present? }
  end

  def valid_location_polygon?(polygon, width:, height:)
    polygon.is_a?(Array) && polygon.size >= 3 && polygon.all? do |point|
      point.is_a?(Array) && point.size == 2 &&
        point[0].is_a?(Integer) && point[0].between?(0, width) &&
        point[1].is_a?(Integer) && point[1].between?(0, height)
    end
  end

  def destination_coordinates_valid?
    destination_x&.between?(0, destination_zone.width - 1) &&
      destination_y&.between?(0, destination_zone.height - 1)
  end
end
