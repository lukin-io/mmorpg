# frozen_string_literal: true

require "rails_helper"

RSpec.describe Battle do
  describe "associations" do
    let(:character) { create(:character, :with_position) }
    let(:zone) { create(:zone) }
    let(:battle) { create(:battle, initiator: character, zone: zone) }

    it "belongs to zone (optional)" do
      expect(battle.zone).to eq(zone)

      # Test optional
      battle_without_zone = create(:battle, initiator: character, zone: nil)
      expect(battle_without_zone).to be_valid
    end

    it "belongs to initiator" do
      expect(battle.initiator).to eq(character)
    end

    it "has many battle_participants" do
      participant = create(:battle_participant, battle: battle, character: character)
      expect(battle.battle_participants).to include(participant)
    end

    it "destroys battle_participants when destroyed" do
      create(:battle_participant, battle: battle, character: character)
      expect { battle.destroy }.to change(BattleParticipant, :count).by(-1)
    end

    it "has many combat_log_entries" do
      entry = create(:combat_log_entry, battle: battle)
      expect(battle.combat_log_entries).to include(entry)
    end

    it "destroys combat_log_entries when destroyed" do
      create(:combat_log_entry, battle: battle)
      expect { battle.destroy }.to change(CombatLogEntry, :count).by(-1)
    end
  end

  describe "validations" do
    let(:character) { create(:character, :with_position) }

    it "requires turn_number to be greater than 0" do
      battle = build(:battle, initiator: character, turn_number: 0)
      expect(battle).not_to be_valid
      expect(battle.errors[:turn_number]).to be_present
    end

    it "accepts valid turn_number" do
      battle = build(:battle, initiator: character, turn_number: 1)
      expect(battle).to be_valid
    end

    context "pvp_mode validation" do
      it "allows valid pvp modes" do
        Battle::PVP_MODES.each do |mode|
          battle = build(:battle, initiator: character, pvp_mode: mode)
          expect(battle).to be_valid
        end
      end

      it "allows nil pvp_mode" do
        battle = build(:battle, initiator: character, pvp_mode: nil)
        expect(battle).to be_valid
      end

      it "rejects invalid pvp modes" do
        battle = build(:battle, initiator: character, pvp_mode: "invalid_mode")
        expect(battle).not_to be_valid
        expect(battle.errors[:pvp_mode]).to be_present
      end
    end
  end

  describe "enums" do
    describe "battle_type" do
      it "has pve, pvp, arena types" do
        expect(Battle.battle_types.keys).to include("pve", "pvp", "arena")
      end

      it "defaults to pve" do
        expect(Battle.new.battle_type).to eq("pve")
      end

      it "can be set to pvp" do
        battle = Battle.new(battle_type: :pvp)
        expect(battle).to be_pvp
      end

      it "can be set to arena" do
        battle = Battle.new(battle_type: :arena)
        expect(battle).to be_arena
      end
    end

    describe "status" do
      it "has pending, active, completed statuses" do
        expect(Battle.statuses.keys).to include("pending", "active", "completed")
      end

      it "defaults to pending" do
        expect(Battle.new.status).to eq("pending")
      end

      it "can be set to active" do
        battle = Battle.new(status: :active)
        expect(battle).to be_active
      end

      it "can be set to completed" do
        battle = Battle.new(status: :completed)
        expect(battle).to be_completed
      end
    end
  end

  describe "callbacks" do
    let(:character) { create(:character, :with_position) }

    describe "before_create :generate_share_token" do
      it "generates a share token on creation" do
        battle = create(:battle, initiator: character)
        expect(battle.share_token).to be_present
        expect(battle.share_token.length).to be > 10
      end

      it "generates unique share tokens" do
        tokens = 5.times.map { create(:battle, initiator: character).share_token }
        expect(tokens.uniq.size).to eq(5)
      end
    end
  end

  describe "class methods" do
    let(:character) { create(:character, :with_position) }

    describe ".find_by_share_token!" do
      let!(:battle) { create(:battle, initiator: character) }

      it "finds battle by share token" do
        found = described_class.find_by_share_token!(battle.share_token)
        expect(found).to eq(battle)
      end

      it "raises error for invalid token" do
        expect { described_class.find_by_share_token!("invalid") }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "instance methods" do
    let(:character) { create(:character, :with_position) }
    let(:battle) { create(:battle, initiator: character) }

    describe "#next_sequence_for" do
      it "returns 1 for first entry in a round" do
        expect(battle.next_sequence_for(1)).to eq(1)
      end

      it "increments sequence for existing entries" do
        battle.combat_log_entries.create!(
          round_number: 1,
          sequence: 1,
          message: "Test"
        )
        expect(battle.next_sequence_for(1)).to eq(2)
      end

      it "tracks sequences per round" do
        battle.combat_log_entries.create!(round_number: 1, sequence: 1, message: "Round 1")
        battle.combat_log_entries.create!(round_number: 1, sequence: 2, message: "Round 1")
        battle.combat_log_entries.create!(round_number: 2, sequence: 1, message: "Round 2")

        expect(battle.next_sequence_for(1)).to eq(3)
        expect(battle.next_sequence_for(2)).to eq(2)
        expect(battle.next_sequence_for(3)).to eq(1)
      end
    end

    describe "#ladder_type" do
      it "returns 'arena' for arena battles" do
        battle.battle_type = :arena
        expect(battle.ladder_type).to eq("arena")
      end

      it "returns pvp_mode for pvp battles with mode" do
        battle.battle_type = :pvp
        battle.pvp_mode = "duel"
        expect(battle.ladder_type).to eq("duel")
      end

      it "returns nil for pve battles" do
        battle.battle_type = :pve
        expect(battle.ladder_type).to be_nil
      end
    end

    describe "#public_url" do
      it "returns URL when share_token present" do
        expect(battle.public_url).to include(battle.share_token)
      end

      it "returns nil when share_token blank" do
        battle.share_token = nil
        expect(battle.public_url).to be_nil
      end
    end

    describe "#public_path" do
      it "returns path when share_token present" do
        expect(battle.public_path).to include(battle.share_token)
      end

      it "returns nil when share_token blank" do
        battle.share_token = nil
        expect(battle.public_path).to be_nil
      end
    end

    describe "#regenerate_share_token!" do
      it "creates a new share token" do
        old_token = battle.share_token
        battle.regenerate_share_token!
        expect(battle.share_token).not_to eq(old_token)
      end
    end
  end

  describe "battle lifecycle" do
    let(:character) { create(:character, :with_position) }
    let(:battle) { create(:battle, initiator: character, status: :active) }

    it "can transition through statuses" do
      expect(battle).to be_active

      battle.update!(status: :completed)
      expect(battle).to be_completed
    end

    it "tracks turn progression" do
      expect(battle.turn_number).to eq(1)

      battle.update!(turn_number: 2)
      expect(battle.turn_number).to eq(2)
    end

    it "maintains initiative order" do
      battle.update!(initiative_order: %w[player enemy])
      expect(battle.initiative_order).to eq(%w[player enemy])
    end
  end
end
