# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manage::ContentMutation do
  let(:actor) { create(:user, :admin) }

  it "creates content and its filtered audit event atomically" do
    record = MapTileTemplate.new

    expect {
      described_class.new(
        actor:,
        record:,
        operation: :create,
        attributes: {zone: "Managed Region", x: 1, y: 2, terrain_type: "outdoor", passable: true, metadata: {}}
      ).call
    }.to change(MapTileTemplate, :count).by(1).and change(ManagementAuditEvent, :count).by(1)

    expect(ManagementAuditEvent.last).to have_attributes(
      actor:,
      action: "create",
      record_type: "MapTileTemplate",
      record_id: record.id
    )
  end

  it "cancels a live capability when targeted content changes" do
    zone = create(:zone, :mvp_outdoor_region)
    cell = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5)
    offer = create(:world_action_offer, zone:, x: 5, y: 5, target: cell)

    described_class.new(actor:, record: cell, operation: :update, attributes: {passable: false}).call

    expect(cell.reload).not_to be_passable
    expect(offer.reload).to be_cancelled
    expect(ManagementAuditEvent.last.change_set).to include("passable")
  end

  it "rolls back a failed mutation without writing an audit event" do
    cell = create(:map_tile_template)

    expect {
      expect {
        described_class.new(actor:, record: cell, operation: :update, attributes: {x: -1}).call
      }.to raise_error(ActiveRecord::RecordInvalid)
    }.not_to change(ManagementAuditEvent, :count)

    expect(cell.reload.x).to be >= 0
  end

  it "records destroyed content after cancelling its live capability" do
    zone = create(:zone, :mvp_outdoor_region)
    cell = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5)
    offer = create(:world_action_offer, zone:, x: 5, y: 5, target: cell)

    described_class.new(actor:, record: cell, operation: :destroy).call

    expect(cell).to be_destroyed
    expect(offer.reload).to be_cancelled
    expect(ManagementAuditEvent.last).to have_attributes(action: "destroy", record_id: cell.id)
  end
end
