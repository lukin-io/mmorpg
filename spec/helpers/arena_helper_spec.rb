# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaHelper, type: :helper do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10, current_hp: 80, max_hp: 100) }
  let(:arena_room) do
    create(:arena_room, name: "Training Hall", level_min: 1, level_max: 100, active: true)
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
        expect(reason).to include("Recover")
        expect(reason).to include("30%")
        expect(reason).to include("50%")
      end
    end

    context "when character is nil" do
      it "returns not logged in message" do
        expect(helper.arena_access_reason(nil)).to eq("No character")
      end
    end
  end

  describe "#fight_type_with_icon" do
    it "returns label for duel" do
      result = helper.fight_type_with_icon("duel")
      expect(result).to eq("Duels")
    end

    it "returns label for team_battle" do
      result = helper.fight_type_with_icon("team_battle")
      expect(result).to eq("Team Battles")
    end

    it "handles unknown fight types gracefully" do
      result = helper.fight_type_with_icon("unknown")
      expect(result).to eq("Unknown")
    end
  end

  describe "#room_type_badge" do
    it "returns badge for training room" do
      badge = helper.room_type_badge(:training)
      expect(badge).to include("Training Hall")
    end

    it "returns badge for trial room" do
      badge = helper.room_type_badge(:trial)
      expect(badge).to include("Trial Hall")
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

  describe "#arena_block_options" do
    it "exposes only the participant's physical table by default" do
      options = helper.arena_block_options(participation)

      expect(options).to include("head_block", "torso_block", "legs_head_block")
      expect(options).not_to include("shield_40_head_block", "magic_shield")
    end

    it "adds only source-injected magic blocks" do
      arena_match.update!(
        metadata: {
          "combat_profile" => {
            "injected_block_keys" => %w[magic_shield rainbow_barrier crystal_sphere]
          }
        }
      )

      expect(helper.arena_block_options(participation)).to include(
        "magic_shield",
        "rainbow_barrier",
        "crystal_sphere"
      )
    end

    it "uses one explicitly authored shield table instead of normal blocks" do
      shield = create(:item_template,
        name: "Arena Shield",
        slot: "off_hand",
        stat_modifiers: {"shield_block_table" => 70})
      create(:inventory_item, inventory: character.inventory, item_template: shield, equipped: true)

      options = helper.arena_block_options(participation)

      expect(options).to include("shield_70_head_block", "shield_70_legs_head_stomach_block")
      expect(options).not_to include("head_block", "shield_40_head_block", "shield_90_head_torso_stomach_block")
    end
  end


  describe "#arena_attack_options" do
    it "exposes physical attacks without inventing selector injections" do
      expect(helper.arena_attack_options(participation).keys).to eq(%w[simple aimed])
    end

    it "adds attacks injected by the captured fight profile" do
      arena_match.update!(
        metadata: {
          "combat_profile" => {
            "injected_attack_keys" => %w[spirit_arrow mind_blast]
          }
        }
      )

      expect(helper.arena_attack_options(participation).keys).to eq(
        %w[simple aimed spirit_arrow mind_blast]
      )
    end
  end
end
