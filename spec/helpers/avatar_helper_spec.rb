# frozen_string_literal: true

require "rails_helper"

RSpec.describe AvatarHelper, type: :helper do
  describe "PLAYER_AVATARS" do
    it "contains all available player avatars" do
      expect(AvatarHelper::PLAYER_AVATARS).to contain_exactly(
        "dwarven", "nightveil", "lightbearer", "pathfinder", "arcanist", "ironbound"
      )
    end

    it "is frozen" do
      expect(AvatarHelper::PLAYER_AVATARS).to be_frozen
    end
  end

  describe "NPC_AVATARS" do
    it "contains arena_bot mapping" do
      expect(AvatarHelper::NPC_AVATARS[:arena_bot]).to eq("scarecrow")
    end

    it "contains open world monster mappings" do
      expect(AvatarHelper::NPC_AVATARS[:wolf]).to eq("wolf")
      expect(AvatarHelper::NPC_AVATARS[:boar]).to eq("boar")
      expect(AvatarHelper::NPC_AVATARS[:skeleton]).to eq("skeleton")
      expect(AvatarHelper::NPC_AVATARS[:zombie]).to eq("zombie")
    end
  end

  describe "#character_avatar_tag" do
    let(:character) { create(:character, avatar: "dwarven") }

    it "returns image tag for character avatar" do
      result = helper.character_avatar_tag(character)
      # Asset fingerprinting adds hash, so use regex
      expect(result).to match(/avatars\/dwarven/)
      expect(result).to include('class="avatar')
    end

    it "uses character name as alt text" do
      result = helper.character_avatar_tag(character)
      expect(result).to include("alt=\"#{character.name}\"")
    end

    it "applies size class" do
      result = helper.character_avatar_tag(character, size: :large)
      expect(result).to include("avatar--large")
    end

    it "handles nil character with fallback" do
      result = helper.character_avatar_tag(nil)
      expect(result).to include("avatar--fallback")
    end

    context "with character without avatar" do
      let(:character_no_avatar) { create(:character, avatar: nil) }

      it "uses random avatar" do
        result = helper.character_avatar_tag(character_no_avatar)
        expect(result).to match(/avatars\//)
      end
    end
  end

  describe "#npc_avatar_tag" do
    context "with arena bot" do
      let(:arena_bot) { create(:npc_template, role: "arena_bot", npc_key: "training_dummy") }

      it "uses scarecrow image" do
        result = helper.npc_avatar_tag(arena_bot)
        expect(result).to match(/npc\/scarecrow/)
      end

      it "includes npc-avatar class" do
        result = helper.npc_avatar_tag(arena_bot)
        expect(result).to include("npc-avatar")
      end
    end

    context "with hostile NPC matching key" do
      let(:wolf) { create(:npc_template, role: "hostile", npc_key: "forest_wolf") }
      let(:boar) { create(:npc_template, role: "hostile", npc_key: "wild_boar") }
      let(:zombie) { create(:npc_template, role: "hostile", npc_key: "bog_zombie") }
      let(:skeleton) { create(:npc_template, role: "hostile", npc_key: "ancient_skeleton") }

      it "matches wolf to wolf image" do
        result = helper.npc_avatar_tag(wolf)
        expect(result).to match(/npc\/wolf/)
      end

      it "matches boar to boar image" do
        result = helper.npc_avatar_tag(boar)
        expect(result).to match(/npc\/boar/)
      end

      it "matches zombie to zombie image" do
        result = helper.npc_avatar_tag(zombie)
        expect(result).to match(/npc\/zombie/)
      end

      it "matches skeleton to skeleton image" do
        result = helper.npc_avatar_tag(skeleton)
        expect(result).to match(/npc\/skeleton/)
      end
    end

    context "with explicit avatar_image in metadata" do
      let(:npc) do
        create(:npc_template,
          role: "hostile",
          npc_key: "custom_npc",
          metadata: {"avatar_image" => "boar.png"})
      end

      it "uses metadata avatar_image over defaults" do
        result = helper.npc_avatar_tag(npc)
        expect(result).to match(/npc\/boar/)
      end
    end

    context "with unmatched hostile NPC" do
      let(:goblin) { create(:npc_template, role: "hostile", npc_key: "goblin_scout") }

      it "uses a random open world avatar" do
        result = helper.npc_avatar_tag(goblin)
        expect(result).to match(/npc\//)
        expect(result).to match(/wolf|boar|skeleton|zombie/)
      end
    end

    it "handles nil NPC with fallback" do
      result = helper.npc_avatar_tag(nil)
      expect(result).to include("avatar--fallback")
    end
  end

  describe "#participation_avatar_tag" do
    context "with character participation" do
      let(:character) { create(:character, avatar: "nightveil") }
      let(:participation) { create(:arena_participation, character: character) }

      it "renders character avatar" do
        result = helper.participation_avatar_tag(participation)
        expect(result).to match(/avatars\/nightveil/)
      end
    end

    context "with NPC participation" do
      let(:npc) { create(:npc_template, role: "arena_bot", npc_key: "arena_dummy") }
      let(:participation) { create(:arena_participation, :npc, npc_template: npc) }

      it "renders NPC avatar" do
        result = helper.participation_avatar_tag(participation)
        expect(result).to match(/npc\/scarecrow/)
      end
    end
  end

  describe "#battle_participant_avatar_tag" do
    context "with character participant" do
      let(:character) { create(:character, avatar: "arcanist") }
      let(:battle) { create(:battle) }
      let(:participant) { create(:battle_participant, battle: battle, character: character) }

      it "renders character avatar" do
        result = helper.battle_participant_avatar_tag(participant)
        expect(result).to match(/avatars\/arcanist/)
      end
    end

    context "with NPC participant" do
      let(:npc) { create(:npc_template, role: "hostile", npc_key: "forest_wolf") }
      let(:battle) { create(:battle) }
      let(:participant) { create(:battle_participant, battle: battle, npc_template: npc, character: nil) }

      it "renders NPC avatar" do
        result = helper.battle_participant_avatar_tag(participant)
        expect(result).to match(/npc\/wolf/)
      end
    end
  end

  describe "#random_player_avatar" do
    it "returns one of the available avatars" do
      expect(AvatarHelper::PLAYER_AVATARS).to include(helper.random_player_avatar)
    end
  end

  describe "#available_player_avatars" do
    it "returns a copy of PLAYER_AVATARS" do
      result = helper.available_player_avatars
      expect(result).to eq(AvatarHelper::PLAYER_AVATARS)
      expect(result).not_to be(AvatarHelper::PLAYER_AVATARS) # Should be a copy
    end
  end
end
