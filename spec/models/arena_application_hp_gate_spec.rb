# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaApplication, "HP Recovery Gate" do
  let(:arena_room) do
    create(:arena_room,
      name: "Test Arena",
      level_min: 1,
      level_max: 100,
      active: true)
  end
  let(:applicant) { create(:character, level: 10, current_hp: 100, max_hp: 100) }
  let(:acceptor) { create(:character, level: 10, current_hp: 100, max_hp: 100) }

  let(:application) do
    create(:arena_application,
      arena_room: arena_room,
      applicant: applicant,
      fight_type: :duel,
      fight_kind: :free,
      timeout_seconds: 300,
      trauma_percent: 30,
      status: :open)
  end

  before do
    create(:character_position, character: applicant)
    create(:character_position, character: acceptor)
  end

  describe "#character_hp_sufficient?" do
    context "when character has full HP" do
      it "returns true" do
        expect(application.character_hp_sufficient?(acceptor)).to be true
      end
    end

    context "when character has exactly 50% HP" do
      before { acceptor.update!(current_hp: 50) }

      it "returns true (at minimum threshold)" do
        expect(application.character_hp_sufficient?(acceptor)).to be true
      end
    end

    context "when character has 49% HP" do
      before { acceptor.update!(current_hp: 49) }

      it "returns false (below threshold)" do
        expect(application.character_hp_sufficient?(acceptor)).to be false
      end
    end

    context "when character has very low HP" do
      before { acceptor.update!(current_hp: 10) }

      it "returns false" do
        expect(application.character_hp_sufficient?(acceptor)).to be false
      end
    end

    context "when character has max_hp of zero (edge case)" do
      before { acceptor.update!(current_hp: 0, max_hp: 0) }

      it "returns true (avoids division by zero)" do
        expect(application.character_hp_sufficient?(acceptor)).to be true
      end
    end
  end

  describe "#acceptable_by?" do
    context "when character has sufficient HP" do
      it "returns true" do
        expect(application.acceptable_by?(acceptor)).to be true
      end
    end

    context "when character has insufficient HP" do
      before { acceptor.update!(current_hp: 30) }

      it "returns false" do
        expect(application.acceptable_by?(acceptor)).to be false
      end
    end

    context "when checking own application" do
      it "returns false (can't accept own application)" do
        expect(application.acceptable_by?(applicant)).to be false
      end
    end
  end

  describe "#rejection_reason_for" do
    context "when character has insufficient HP" do
      before { acceptor.update!(current_hp: 30) }

      it "returns HP recovery message" do
        reason = application.rejection_reason_for(acceptor)
        expect(reason).to include("Recover before fighting")
        expect(reason).to include("50%")
      end
    end

    context "when character can accept" do
      it "returns nil" do
        expect(application.rejection_reason_for(acceptor)).to be_nil
      end
    end

    context "when application is not open" do
      before { application.update!(status: :cancelled) }

      it "returns appropriate message" do
        expect(application.rejection_reason_for(acceptor)).to eq("Application is closed")
      end
    end

    context "when level doesn't match" do
      before { acceptor.update!(level: 200) }

      it "returns appropriate access message" do
        reason = application.rejection_reason_for(acceptor)
        # May be level or room access depending on validation order
        expect(reason).to include("Arena room").or include("level")
      end
    end
  end

  describe "MIN_HP_PERCENT_FOR_ARENA constant" do
    it "is set to 50" do
      expect(ArenaApplication::MIN_HP_PERCENT_FOR_ARENA).to eq(50)
    end
  end
end
