require "rails_helper"

RSpec.describe Character, type: :model do
  describe "inheritance" do
    it "inherits guild and clan membership from the owner" do
      user = create(:user)
      guild = create(:guild, leader: user)
      clan = create(:clan, leader: user)
      create(:guild_membership, guild: guild, user: user, status: :active)
      create(:clan_membership, clan: clan, user: user)

      character = create(:character, user: user)

      expect(character.guild).to eq(user.primary_guild)
      expect(character.clan).to eq(user.primary_clan)
    end
  end

  describe "limits" do
    it "prevents creating more than the allowed number of characters" do
      user = create(:user)
      User::MAX_CHARACTERS.times { create(:character, user: user) }

      extra_character = build(:character, user: user)

      expect(extra_character).not_to be_valid
      expect(extra_character.errors[:base]).to include("character limit reached")
    end
  end

  describe "alignment tiers" do
    let(:character) { create(:character) }

    describe "#alignment_tier" do
      it "returns celestial for high positive score" do
        character.update!(alignment_score: 900)
        expect(character.alignment_tier).to eq(:celestial)
      end

      it "returns neutral for scores near zero" do
        character.update!(alignment_score: 0)
        expect(character.alignment_tier).to eq(:neutral)
      end

      it "returns absolute_darkness for very low score" do
        character.update!(alignment_score: -900)
        expect(character.alignment_tier).to eq(:absolute_darkness)
      end

      it "returns true_light for high-mid positive score" do
        character.update!(alignment_score: 600)
        expect(character.alignment_tier).to eq(:true_light)
      end

      it "returns child_of_darkness for mid-range negative score" do
        character.update!(alignment_score: -300)
        expect(character.alignment_tier).to eq(:child_of_darkness)
      end
    end

    describe "#alignment_emoji" do
      it "returns angel emoji for celestial tier" do
        character.update!(alignment_score: 900)
        expect(character.alignment_emoji).to eq("👼")
      end

      it "returns yin-yang for neutral tier" do
        character.update!(alignment_score: 0)
        expect(character.alignment_emoji).to eq("☯️")
      end

      it "returns black heart for absolute darkness" do
        character.update!(alignment_score: -900)
        expect(character.alignment_emoji).to eq("🖤")
      end
    end

    describe "#adjust_alignment!" do
      it "increases alignment score" do
        character.update!(alignment_score: 0)
        character.adjust_alignment!(100)
        expect(character.alignment_score).to eq(100)
      end

      it "clamps to maximum of 1000" do
        character.update!(alignment_score: 950)
        character.adjust_alignment!(100)
        expect(character.alignment_score).to eq(1000)
      end

      it "clamps to minimum of -1000" do
        character.update!(alignment_score: -950)
        character.adjust_alignment!(-100)
        expect(character.alignment_score).to eq(-1000)
      end
    end
  end

  describe "chaos tiers" do
    let(:character) { create(:character, chaos_score: 0) }

    describe "#chaos_tier" do
      it "returns lawful for low score" do
        expect(character.chaos_tier).to eq(:lawful)
      end

      it "returns absolute_chaos for high score" do
        character.update!(chaos_score: 900)
        expect(character.chaos_tier).to eq(:absolute_chaos)
      end

      it "returns chaotic for mid-high score" do
        character.update!(chaos_score: 600)
        expect(character.chaos_tier).to eq(:chaotic)
      end
    end

    describe "#chaos_emoji" do
      it "returns scales for lawful" do
        expect(character.chaos_emoji).to eq("⚖️")
      end

      it "returns explosion for absolute chaos" do
        character.update!(chaos_score: 900)
        expect(character.chaos_emoji).to eq("💥")
      end
    end

    describe "#adjust_chaos!" do
      it "increases chaos score" do
        character.adjust_chaos!(50)
        expect(character.chaos_score).to eq(50)
      end

      it "clamps to maximum of 1000" do
        character.update!(chaos_score: 980)
        character.adjust_chaos!(50)
        expect(character.chaos_score).to eq(1000)
      end

      it "clamps to minimum of 0" do
        character.update!(chaos_score: 10)
        character.adjust_chaos!(-50)
        expect(character.chaos_score).to eq(0)
      end
    end
  end

  describe "faction display" do
    let(:character) { create(:character) }

    describe "#faction_emoji" do
      it "returns shield for alliance" do
        character.update!(faction_alignment: "alliance")
        expect(character.faction_emoji).to eq("🛡️")
      end

      it "returns sword for rebellion" do
        character.update!(faction_alignment: "rebellion")
        expect(character.faction_emoji).to eq("⚔️")
      end

      it "returns flag for neutral" do
        character.update!(faction_alignment: "neutral")
        expect(character.faction_emoji).to eq("🏳️")
      end
    end

    describe "#alignment_display" do
      it "combines faction and tier information" do
        character.update!(faction_alignment: "alliance", alignment_score: 600)
        display = character.alignment_display
        expect(display).to include("🛡️")  # faction
        expect(display).to include("✨")   # true light
        expect(display).to include("True Light")
      end
    end
  end
end
