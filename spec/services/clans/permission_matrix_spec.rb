# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clans::PermissionMatrix do
  let(:clan) { create(:clan) }
  let(:membership) { create(:clan_membership, clan: clan, role: :officer) }

  describe ".seed_defaults!" do
    it "creates permission rows for every role" do
      clan.clan_role_permissions.destroy_all
      described_class.seed_defaults!(clan: clan)
      expect(clan.clan_role_permissions.count).to be > 0
    end
  end

  describe "#allows?" do
    it "returns true when the stored permission is enabled" do
      permission = clan.clan_role_permissions.find_by(role: :officer, permission_key: "manage_recruitment")
      permission.update!(enabled: true)
      matrix = described_class.new(clan: clan, membership: membership)
      expect(matrix.allows?(:manage_recruitment)).to be(true)
    end

    it "falls back to defaults when no override exists" do
      matrix = described_class.new(clan: clan, membership: membership)
      default = Rails.configuration.x.clans.dig("permissions", "defaults", "officer", "manage_recruitment")
      expect(matrix.allows?(:manage_recruitment)).to eq(!!default)
    end
  end
end
