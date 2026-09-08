# frozen_string_literal: true

module Manage
  # Normalizes the guided cell editor into the existing metadata owner.
  # Inputs are permitted form attributes and the current cell; output is an
  # assignment hash. It performs no writes and preserves unedited action data.
  class WorldCellAttributes
    def initialize(attributes:, cell:)
      @attributes = attributes.deep_dup
      @cell = cell
    end

    def call
      return attributes unless attributes.delete("content_fields") == "1"

      metadata = attributes.fetch("metadata")
      metadata["local_actions"] = local_actions(attributes.delete("local_actions").to_h)
      metadata["resource_groups"] = resource_groups(attributes.delete("resource_groups").to_h)
      attributes
    end

    private

    attr_reader :attributes, :cell

    def local_actions(values)
      MapTileTemplate::LOCAL_ACTION_DEFINITIONS.filter_map do |type, definition|
        submitted = values.fetch(type, {}).to_h
        existing = cell.local_actions.find { |entry| entry["type"] == type }
        active = boolean(submitted["active"])
        next unless active || existing

        (existing || {}).merge(
          "type" => type, "source_id" => definition.fetch("source_id"),
          "label" => submitted["label"].presence || definition.fetch("default_label"),
          "active" => active
        )
      end
    end

    def resource_groups(values)
      values.values.filter_map do |raw|
        entry = raw.to_h.slice("key", "kind", "label", "active")
        next if entry.except("active").values.all?(&:blank?)

        existing = cell.resource_groups.find { |group| group["key"] == entry["key"] } || {}
        existing.merge(entry).merge("active" => boolean(entry["active"]))
      end
    end

    def boolean(value)
      return true if [true, "1"].include?(value)
      return false if [false, "0", nil].include?(value)

      value # Model validation reports malformed values instead of coercing them.
    end
  end
end
