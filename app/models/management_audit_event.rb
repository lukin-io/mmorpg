# frozen_string_literal: true

# Immutable audit trail for authenticated management mutations.
class ManagementAuditEvent < ApplicationRecord
  ACTIONS = %w[create update destroy].freeze

  belongs_to :actor, class_name: "User", inverse_of: :management_audit_events

  validates :action, inclusion: {in: ACTIONS}
  validates :record_type, :record_label, presence: true

  def readonly?
    persisted?
  end

  def destroy
    raise ActiveRecord::ReadOnlyRecord, "management audit events are immutable"
  end
end
