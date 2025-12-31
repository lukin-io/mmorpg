# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaHelper, "PVP UI Methods" do
  let(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true, max_concurrent_matches: 5) }
  let(:arena_season) { create(:arena_season, status: :live) }
  let(:character1) { create(:character, name: "WarriorOne", level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, name: "MageTwo", level: 10, current_hp: 100, max_hp: 100) }

  let(:match) do
    create(:arena_match,
      arena_room: arena_room,
      arena_season: arena_season,
      status: :live,
      match_type: :duel,
      started_at: 5.minutes.ago)
  end

  let!(:participation1) { create(:arena_participation, arena_match: match, character: character1, user: character1.user, team: "a") }
  let!(:participation2) { create(:arena_participation, arena_match: match, character: character2, user: character2.user, team: "b") }

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
  end

  describe "#winner_name" do
    context "when match has no winner (draw)" do
      before do
        match.update!(status: :completed, winning_team: nil)
      end

      it "returns 'Draw'" do
        expect(helper.winner_name(match)).to eq("Draw")
      end
    end

    context "when match is ongoing (no winner yet)" do
      it "returns 'Draw' since no winner set" do
        expect(helper.winner_name(match)).to eq("Draw")
      end
    end

    context "when team a wins (player character)" do
      before do
        match.update!(status: :completed, winning_team: "a")
      end

      it "returns the winning character name" do
        expect(helper.winner_name(match)).to eq("WarriorOne")
      end
    end

    context "when team b wins (player character)" do
      before do
        match.update!(status: :completed, winning_team: "b")
      end

      it "returns the winning character name" do
        expect(helper.winner_name(match)).to eq("MageTwo")
      end
    end

    context "when winner is an NPC" do
      let(:npc_template) { create(:npc_template, name: "Training Dummy", level: 5) }

      before do
        # Create NPC participation without character
        create(:arena_participation,
          arena_match: match,
          npc_template: npc_template,
          character: nil,
          team: "c",
          metadata: {"current_hp" => 100, "max_hp" => 100})
        match.update!(status: :completed, winning_team: "c")
      end

      it "returns the NPC name" do
        expect(helper.winner_name(match)).to eq("Training Dummy")
      end
    end
  end

  describe "#format_duration" do
    it "formats nil duration as 0s" do
      expect(helper.format_duration(nil)).to eq("0s")
    end

    it "formats 0 duration as 0s" do
      expect(helper.format_duration(0)).to eq("0s")
    end

    it "formats short durations in seconds" do
      expect(helper.format_duration(45)).to eq("45s")
    end

    it "formats exactly one minute" do
      expect(helper.format_duration(60)).to eq("1m")
    end

    it "formats minutes and seconds" do
      expect(helper.format_duration(125)).to eq("2m 5s")
    end

    it "formats long durations in hours" do
      expect(helper.format_duration(3661)).to eq("1h 1m") # 1 hour, 1 minute, 1 second
    end
  end

  describe "#hp_color_class" do
    it "returns 'high' for HP > 75%" do
      expect(helper.hp_color_class(100)).to eq("high")
      expect(helper.hp_color_class(76)).to eq("high")
    end

    it "returns 'medium' for HP between 51-75%" do
      expect(helper.hp_color_class(75)).to eq("medium")
      expect(helper.hp_color_class(51)).to eq("medium")
    end

    it "returns 'low' for HP between 26-50%" do
      expect(helper.hp_color_class(50)).to eq("low")
      expect(helper.hp_color_class(26)).to eq("low")
    end

    it "returns 'critical' for HP 0-25%" do
      expect(helper.hp_color_class(25)).to eq("critical")
      expect(helper.hp_color_class(0)).to eq("critical")
    end

    it "handles edge cases" do
      # Negative values fall through to "high" (Ruby case behavior)
      # This is acceptable as HP should never be negative in practice
      expect(helper.hp_color_class(150)).to eq("high")
    end
  end

  describe "#participant_data" do
    context "for player character" do
      it "returns ParticipantData struct with correct values" do
        data = helper.participant_data(participation1)

        expect(data).to be_a(ArenaHelper::ParticipantData)
        expect(data.name).to eq("WarriorOne")
        expect(data.level).to eq(10)
        expect(data.is_npc).to be false
        expect(data.current_hp).to eq(100)
        expect(data.max_hp).to eq(100)
        expect(data.hp_percent).to eq(100)
      end

      it "calculates HP percentage correctly" do
        character1.update!(current_hp: 30, max_hp: 100)
        data = helper.participant_data(participation1)

        expect(data.hp_percent).to eq(30)
      end
    end

    context "for NPC participant" do
      let(:npc_template) { create(:npc_template, name: "Training Bot", level: 3) }
      let!(:npc_participation) do
        create(:arena_participation,
          arena_match: match,
          npc_template: npc_template,
          character: nil,
          team: "b",
          metadata: {"current_hp" => 80, "max_hp" => 100})
      end

      it "returns ParticipantData with NPC values" do
        data = helper.participant_data(npc_participation)

        expect(data.name).to eq("Training Bot")
        expect(data.level).to eq(3)
        expect(data.is_npc).to be true
        expect(data.current_hp).to eq(80)
        expect(data.max_hp).to eq(100)
        expect(data.hp_percent).to eq(80)
      end
    end
  end

  describe "#current_user_participating?" do
    # Note: These methods require current_user from session context
    # They are tested via request/system specs with actual authentication
    # This tests the @arena_match ivar requirement

    it "returns false when @arena_match is not set" do
      # current_user returns nil from helper in test environment
      expect(helper.current_user_participating?).to be false
    end
  end

  describe "#current_user_won?" do
    # Note: These methods require current_user from session context
    # They are tested via request/system specs with actual authentication

    it "returns false when @arena_match is not set" do
      expect(helper.current_user_won?).to be false
    end

    it "returns false when match has no winning team" do
      helper.instance_variable_set(:@arena_match, match)
      expect(helper.current_user_won?).to be false
    end
  end
end
