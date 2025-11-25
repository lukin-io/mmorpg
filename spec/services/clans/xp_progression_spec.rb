# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clans::XpProgression do
  let(:clan) { create(:clan, experience: 0, level: 1, unlocked_buffs: []) }
  subject(:service) { described_class.new(clan: clan) }

  describe "#grant!" do
    it "creates an XP event and levels up the clan when thresholds are met" do
      threshold = service.threshold_for(clan.level + 1)
      expect do
        service.grant!(amount: threshold + 100, source: "test")
      end.to change { clan.reload.level }.by(1)
        .and change { clan.clan_xp_events.count }.by(1)
    end
  end
end
