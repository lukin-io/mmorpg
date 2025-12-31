# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaHelper, type: :helper do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10, current_hp: 80, max_hp: 100) }
  let(:arena_room) do
    create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true)
  end
  let(:arena_match) do
    create(:arena_match, arena_room: arena_room, status: :live, match_type: :duel)
  end
  let!(:participation) do
    create(:arena_participation,
      arena_match: arena_match,
      character: character,
      user: user,
      team: "a")
  end

  before do
    create(:character_position, character: character)
  end

  describe "#participant_data" do
    context "with character participation" do
      it "returns correct name and level" do
        data = helper.participant_data(participation)
        expect(data.name).to eq(character.name)
        expect(data.level).to eq(character.level)
      end

      it "returns correct HP values" do
        data = helper.participant_data(participation)
        expect(data.current_hp).to eq(character.current_hp)
        expect(data.max_hp).to eq(character.max_hp)
      end

      it "calculates HP percentage correctly" do
        data = helper.participant_data(participation)
        expect(data.hp_percent).to eq(80.0)
      end

      it "marks as not NPC" do
        data = helper.participant_data(participation)
        expect(data.is_npc).to be false
      end
    end
  end

  describe "#arena_access_reason" do
    context "when character has sufficient HP" do
      before { character.update!(current_hp: 80, max_hp: 100) }

      it "returns nil" do
        expect(helper.arena_access_reason(character)).to be_nil
      end
    end

    context "when character has insufficient HP" do
      before { character.update!(current_hp: 30, max_hp: 100) }

      it "returns HP recovery warning" do
        reason = helper.arena_access_reason(character)
        expect(reason).to include("Recover before fighting")
        expect(reason).to include("30%")
        expect(reason).to include("50%")
      end
    end

    context "when character is nil" do
      it "returns not logged in message" do
        expect(helper.arena_access_reason(nil)).to eq("Not logged in")
      end
    end
  end

  describe "#fight_type_with_icon" do
    it "returns icon and label for duel" do
      result = helper.fight_type_with_icon("duel")
      expect(result).to include("⚔️")
      expect(result).to include("Duel")
    end

    it "returns icon and label for team_battle" do
      result = helper.fight_type_with_icon("team_battle")
      expect(result).to include("👥")
      expect(result).to include("Team Battle")
    end

    it "handles unknown fight types gracefully" do
      result = helper.fight_type_with_icon("unknown")
      expect(result).to include("⚔️")
      expect(result).to include("Unknown")
    end
  end

  describe "#room_type_badge" do
    it "returns badge for training room" do
      badge = helper.room_type_badge(:training)
      expect(badge).to include("🏋️")
      expect(badge).to include("Training Hall")
    end

    it "returns badge for challenge room" do
      badge = helper.room_type_badge(:challenge)
      expect(badge).to include("🗡️")
      expect(badge).to include("Challenge Arena")
    end
  end

  describe "#participation_avatar_tag" do
    context "with player participation" do
      it "returns avatar element with class" do
        html = helper.participation_avatar_tag(participation)
        expect(html).to include("avatar")
      end
    end
  end

  describe "#character_combat_stats" do
    context "with nil character" do
      it "returns empty hash" do
        expect(helper.character_combat_stats(nil)).to eq({})
      end
    end
  end
end
