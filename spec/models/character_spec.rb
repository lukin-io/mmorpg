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
end
