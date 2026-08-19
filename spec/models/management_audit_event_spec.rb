# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManagementAuditEvent, type: :model do
  it "requires a supported action and record identity" do
    event = build(:management_audit_event, action: "publish", record_type: nil, record_label: nil)

    expect(event).not_to be_valid
    expect(event.errors).to include(:action, :record_type, :record_label)
  end

  it "is immutable after creation" do
    event = create(:management_audit_event)

    expect { event.update!(record_label: "Changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "backs its durable identity and action rules with database constraints" do
    record_id_column = described_class.columns_hash.fetch("record_id")
    constraint_names = described_class.connection
      .check_constraints(described_class.table_name)
      .map(&:name)

    expect(record_id_column.null).to be false
    expect(constraint_names).to include("management_audit_events_action_check")
  end
end
