# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileNpcRespawnJob do
  include ActiveSupport::Testing::TimeHelpers

  it "respawns only a due defeated placement and keeps it disabled" do
    npc = create(:tile_npc, :defeated, metadata: {"active" => false}, respawns_at: 1.minute.from_now)
    state = npc.attributes.slice("current_hp", "defeated_at", "respawns_at")
    described_class.perform_now(npc.id)
    expect(npc.reload.attributes.slice(*state.keys)).to eq(state)

    travel_to npc.respawns_at, with_usec: true do
      described_class.perform_now(npc.id)
      expect(npc.reload).not_to be_defeated
      expect(npc).not_to be_active
      npc.update!(current_hp: 10)
      described_class.perform_now(npc.id)
      expect(npc.reload.current_hp).to eq(10)
    end
  end

  it "ignores missing placements and defeated placements without an authored deadline" do
    expect { described_class.perform_now(-1) }.not_to raise_error
    npc = create(:tile_npc, :defeated, respawns_at: nil)
    described_class.perform_now(npc.id)
    expect(npc.reload).to be_defeated
  end
end
