# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::GmConsoleService do
  let(:actor) { create(:user) }
  let(:wallet_instance) { instance_double("Economy::WalletService", adjust!: nil) }
  let(:wallet_class) { double("Economy::WalletService", new: wallet_instance) }
  let(:service) { described_class.new(actor:, wallet_service: wallet_class) }

  before do
    allow(AuditLogger).to receive(:log)
  end

  describe "#spawn_assignment!" do
    it "creates or updates a quest assignment for the character" do
      quest = create(:quest, min_level: 1)
      character = create(:character, level: 5)

      assignment = service.spawn_assignment!(quest_key: quest.key, character_id: character.id)

      expect(assignment).to be_in_progress
      expect(assignment.quest).to eq(quest)
      expect(AuditLogger).to have_received(:log).with(hash_including(action: "gm.spawn_quest"))
    end
  end

  describe "#disable_quest!" do
    it "marks the quest as inactive and records metadata" do
      quest = create(:quest, active: true)

      service.disable_quest!(quest_key: quest.key, reason: "Bugged")

      expect(quest.reload.active).to be(false)
      expect(quest.metadata["gm_disabled_reason"]).to eq("Bugged")
    end
  end

  describe "#adjust_timers!" do
    it "subtracts minutes from assignment timers" do
      quest = create(:quest)
      character = create(:character)
      assignment = create(:quest_assignment, quest:, character:, expires_at: 2.hours.from_now, next_available_at: 3.hours.from_now)

      service.adjust_timers!(quest_key: quest.key, minutes: 60)

      expect(assignment.reload.expires_at).to be_within(1.second).of(1.hour.from_now)
      expect(assignment.next_available_at).to be_within(1.second).of(2.hours.from_now)
    end
  end

  describe "#compensate_players!" do
    it "credits every assignment owner through the wallet service" do
      quest = create(:quest)
      assignment = create(:quest_assignment, quest:, character: create(:character))

      service.compensate_players!(quest_key: quest.key, currency: :gold, amount: 50)

      expect(wallet_class).to have_received(:new).once
      expect(wallet_instance).to have_received(:adjust!).with(hash_including(currency: :gold, amount: 50))
      expect(AuditLogger).to have_received(:log).with(hash_including(action: "gm.compensate_players"))
      expect(assignment.character.user.currency_wallet).to be_present
    end
  end
end
