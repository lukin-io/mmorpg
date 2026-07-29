# frozen_string_literal: true

module Manage
  # Persists an allowlisted management mutation and its audit event atomically.
  #
  # Inputs: authenticated actor, Active Record content record, operation, and
  # controller-normalized attributes. Returns the persisted/destroyed record.
  # Any validation, dependency, or audit failure rolls the complete mutation
  # back. Live capabilities targeting changed content are cancelled in the same
  # transaction so a stale browser offer cannot execute an older definition.
  class ContentMutation
    OPERATIONS = %i[create update destroy].freeze

    def initialize(actor:, record:, operation:, attributes: {})
      @actor = actor
      @record = record
      @operation = operation.to_sym
      @attributes = attributes
    end

    def call
      raise ArgumentError, "unsupported management operation" unless OPERATIONS.include?(operation)

      ApplicationRecord.transaction do
        case operation
        when :create then persist_create!
        when :update then persist_update!
        when :destroy then persist_destroy!
        end
        record_audit_event!
      end

      record
    end

    private

    attr_reader :actor, :record, :operation, :attributes

    def persist_create!
      record.assign_attributes(attributes)
      record.save!
      @audit_changes = filtered_attributes(record.attributes)
    end

    def persist_update!
      record.assign_attributes(attributes)
      record.save!
      @audit_changes = filtered_changes(record.saved_changes.except("updated_at"))
      cancel_targeted_offers! if @audit_changes.any?
    end

    def persist_destroy!
      @audit_changes = filtered_attributes(record.attributes)
      cancel_targeted_offers!
      record.destroy!
    end

    def cancel_targeted_offers!
      return unless defined?(WorldActionOffer)

      statuses = WorldActionOffer.statuses.values_at("offered", "accepted")
      WorldActionOffer.where(target: record, status: statuses).update_all(
        status: WorldActionOffer.statuses.fetch("cancelled"),
        error_message: "Managed world content changed.",
        updated_at: Time.current
      )
    end

    def record_audit_event!
      ManagementAuditEvent.create!(
        actor:,
        action: operation.to_s,
        record_type: record.class.base_class.name,
        record_id: record.id,
        record_label: record_label,
        change_set: @audit_changes || {},
        metadata: {"source" => "manage_namespace"}
      )
    end

    def record_label
      %i[name building_key npc_key key].filter_map do |method_name|
        record.public_send(method_name).presence if record.respond_to?(method_name)
      end.first || "#{record.class.model_name.human} ##{record.id}"
    end

    def filtered_attributes(values)
      parameter_filter.filter(values.except("created_at", "updated_at"))
    end

    def filtered_changes(values)
      parameter_filter.filter(values.transform_values { |before, after| {"from" => before, "to" => after} })
    end

    def parameter_filter
      @parameter_filter ||= ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    end
  end
end
