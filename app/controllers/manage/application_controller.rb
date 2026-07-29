# frozen_string_literal: true

module Manage
  class ApplicationController < ::ApplicationController
    layout "manage"

    skip_before_action :prepare_game_shell_context
    before_action :authorize_management!
    after_action :verify_authorized

    helper_method :management_sections

    private

    def authorize_management!
      authorize :manage, :access?
    end

    def management_sections
      [
        {key: :world_cells, label: "World Cells", path: manage_world_cells_path},
        {key: :tile_buildings, label: "Cell Buildings", path: manage_tile_buildings_path},
        {key: :npc_templates, label: "NPC Catalog", path: manage_npc_templates_path},
        {key: :tile_npcs, label: "Cell NPCs", path: manage_tile_npcs_path},
        {key: :cities, label: "Cities", path: manage_cities_path},
        {key: :city_hotspots, label: "City Actions", path: manage_city_hotspots_path},
        {key: :audit_events, label: "Audit Log", path: manage_audit_events_path}
      ]
    end

    def paginate(relation)
      @pagination = Manage::PaginatedRelation.new(relation:, page: params[:page]).call
      @pagination.records
    end

    def parse_json_attributes(permitted, record, *attribute_names)
      attributes = permitted.to_h

      attribute_names.each do |attribute_name|
        raw_value = attributes[attribute_name.to_s]
        next if raw_value.is_a?(Hash)

        parsed = JSON.parse(raw_value.presence || "{}")
        unless parsed.is_a?(Hash)
          record.errors.add(attribute_name, "must be a JSON object")
          return
        end

        attributes[attribute_name.to_s] = parsed
      rescue JSON::ParserError => e
        record.errors.add(attribute_name, "is not valid JSON: #{e.message}")
        return
      end

      attributes
    end

    def mutate(record, operation:, attributes: {})
      Manage::ContentMutation.new(
        actor: current_user,
        record:,
        operation:,
        attributes:
      ).call
      true
    rescue ActiveRecord::RecordInvalid => e
      copy_errors(e.record, record)
      false
    rescue ActiveRecord::RecordNotDestroyed,
      ActiveRecord::DeleteRestrictionError,
      ActiveRecord::InvalidForeignKey => e
      record.errors.add(:base, e.message)
      false
    end

    def copy_errors(source, destination)
      return if source.equal?(destination)

      source.errors.each { |error| destination.errors.add(error.attribute, error.message) }
    end
  end
end
