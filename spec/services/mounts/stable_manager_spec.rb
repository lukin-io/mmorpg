require "rails_helper"

RSpec.describe Mounts::StableManager do
  let(:user) { create(:user) }
  let(:manager) { described_class.new(user:) }

  describe "#assign_mount!" do
    it "assigns mount to slot" do
      slot = create(:mount_stable_slot, user:, slot_index: 0, status: :unlocked)
      mount = create(:mount, user:)

      manager.assign_mount!(slot_index: slot.slot_index, mount:)

      expect(mount.reload.mount_stable_slot).to eq(slot)
      expect(slot.reload.current_mount).to eq(mount)
    end
  end
end
