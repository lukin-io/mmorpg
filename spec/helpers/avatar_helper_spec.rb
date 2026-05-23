# frozen_string_literal: true

require "rails_helper"

RSpec.describe AvatarHelper, type: :helper do
  describe "NPC_IMAGE_ASSETS" do
    it "keeps monster images available as assets only" do
      expect(AvatarHelper::NPC_IMAGE_ASSETS).to contain_exactly(
        "scarecrow", "wolf", "boar", "skeleton", "zombie"
      )
    end
  end

  describe "#character_avatar_tag" do
    let(:character) { create(:character) }

    it "returns neutral fallback for characters" do
      result = helper.character_avatar_tag(character)

      expect(result).to include("avatar--fallback")
      expect(result).not_to match(/avatars\//)
    end

    it "applies size class" do
      result = helper.character_avatar_tag(character, size: :large)
      expect(result).to include("avatar--large")
    end

    it "handles nil character with fallback" do
      result = helper.character_avatar_tag(nil)
      expect(result).to include("avatar--fallback")
    end
  end

  describe "#npc_avatar_tag" do
    context "with arena bot" do
      let(:arena_bot) { create(:npc_template, role: "arena_bot", npc_key: "training_dummy", metadata: {"avatar_image" => "scarecrow.png"}) }

      it "uses scarecrow image" do
        result = helper.npc_avatar_tag(arena_bot)
        expect(result).to match(/npc\/scarecrow/)
      end

      it "includes npc-avatar class" do
        result = helper.npc_avatar_tag(arena_bot)
        expect(result).to include("npc-avatar")
      end
    end

    context "with hostile NPC explicit image metadata" do
      let(:skeleton_image_npc) { create(:npc_template, role: "hostile", npc_key: "plague_rat", metadata: {"avatar_image" => "skeleton.png"}) }
      let(:zombie_image_npc) { create(:npc_template, role: "hostile", npc_key: "plague_rat_alpha", metadata: {"avatar_image" => "zombie.png"}) }

      it "uses explicit captured NPC image metadata" do
        result = helper.npc_avatar_tag(skeleton_image_npc)
        expect(result).to match(/npc\/skeleton/)
      end

      it "supports another explicit hostile NPC image" do
        result = helper.npc_avatar_tag(zombie_image_npc)
        expect(result).to match(/npc\/zombie/)
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

    context "without explicit image metadata" do
      let(:npc) { create(:npc_template, role: "hostile", npc_key: "plague_rat") }

      it "uses the technical fallback instead of a gameplay-derived image" do
        result = helper.npc_avatar_tag(npc)
        expect(result).to include("avatar--fallback")
      end
    end

    it "handles nil NPC with fallback" do
      result = helper.npc_avatar_tag(nil)
      expect(result).to include("avatar--fallback")
    end
  end

  describe "#participation_avatar_tag" do
    context "with character participation" do
      let(:character) { create(:character) }
      let(:participation) { create(:arena_participation, character: character) }

      it "renders neutral character fallback" do
        result = helper.participation_avatar_tag(participation)
        expect(result).to include("avatar--fallback")
      end
    end

    context "with NPC participation" do
      let(:npc) { create(:npc_template, role: "arena_bot", npc_key: "arena_dummy", metadata: {"avatar_image" => "scarecrow.png"}) }
      let(:participation) { create(:arena_participation, :npc, npc_template: npc) }

      it "renders NPC avatar" do
        result = helper.participation_avatar_tag(participation)
        expect(result).to match(/npc\/scarecrow/)
      end
    end
  end
end
