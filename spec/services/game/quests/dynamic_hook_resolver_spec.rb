# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::DynamicHookResolver do
  let(:character) { create(:character) }
  let!(:dynamic_quest) { create(:quest, quest_type: :dynamic, metadata: {"event_keys" => ["wintertide"]}) }

  describe "#assign_for" do
    it "creates assignments when quest metadata includes the event key" do
      assignments = described_class.new.assign_for(character:, event_key: "wintertide")

      expect(assignments.first).to be_persisted
      expect(assignments.first.quest).to eq(dynamic_quest)
    end
  end
end
