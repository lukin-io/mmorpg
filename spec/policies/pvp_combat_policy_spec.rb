# frozen_string_literal: true

require "rails_helper"

RSpec.describe PvpCombatPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:other_user) { create(:user) }
  let(:other_character) { create(:character, user: other_user) }
  let(:battle) { create(:battle, :active, battle_type: :pvp, initiator: character) }

  before do
    create(:battle_participant, battle: battle, character: character, team: "alpha")
    create(:battle_participant, battle: battle, character: other_character, team: "beta")
  end

  # =============================================================================
  # SUCCESS CASES
  # =============================================================================
  describe "show?" do
    context "when user is a participant" do
      it "permits access" do
        expect(subject.new(user, battle).show?).to be true
      end
    end
  end

  describe "action?" do
    context "when user is a participant and battle is active" do
      it "permits action" do
        expect(subject.new(user, battle).action?).to be true
      end
    end
  end

  describe "flee?" do
    context "when user is a participant and battle is active" do
      it "permits flee" do
        expect(subject.new(user, battle).flee?).to be true
      end
    end
  end

  describe "surrender?" do
    context "when user is a participant and battle is active" do
      it "permits surrender" do
        expect(subject.new(user, battle).surrender?).to be true
      end
    end
  end

  # =============================================================================
  # FAILURE CASES
  # =============================================================================
  describe "action? - failure cases" do
    context "when battle is completed" do
      let(:completed_battle) { create(:battle, :completed, battle_type: :pvp) }

      before do
        create(:battle_participant, battle: completed_battle, character: character)
      end

      it "denies action" do
        expect(subject.new(user, completed_battle).action?).to be false
      end
    end
  end

  # =============================================================================
  # AUTHORIZATION CASES
  # =============================================================================
  describe "show? - authorization" do
    context "when user is not a participant" do
      let(:non_participant_user) { create(:user) }

      it "denies access" do
        expect(subject.new(non_participant_user, battle).show?).to be false
      end
    end

    context "when user is nil (guest)" do
      it "denies access" do
        expect(subject.new(nil, battle).show?).to be false
      end
    end
  end

  describe "action? - authorization" do
    context "when user is not a participant" do
      let(:non_participant_user) { create(:user) }

      it "denies action" do
        expect(subject.new(non_participant_user, battle).action?).to be false
      end
    end
  end

  # =============================================================================
  # EDGE CASES
  # =============================================================================
  describe "edge cases" do
    context "when battle is nil" do
      it "denies all access" do
        expect(subject.new(user, nil).show?).to be false
        expect(subject.new(user, nil).action?).to be false
      end
    end

    context "when character is dead in battle" do
      before do
        battle.battle_participants.find_by(character: character).update!(is_alive: false)
      end

      it "allows viewing but denies action" do
        expect(subject.new(user, battle).show?).to be true
        expect(subject.new(user, battle).action?).to be false
      end
    end
  end
end
