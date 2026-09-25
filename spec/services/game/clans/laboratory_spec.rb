# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Clans::Laboratory do
  let(:character) { create(:character) }

  it "unlocks for a member whose clan owns an active laboratory" do
    clan = Clan.create!(key: "lab-clan", name: "Lab Clan", tag: "LAB", leader_character: character)
    ClanMembership.create!(clan:, character:, role: "leader")
    fortress = WorldFortress.create!(
      zone: "Пепельный Берег", x: 70, y: 70, fortress_key: "lab-fort",
      name: "Lab Fort", kind: "fortress", owner_clan: clan
    )
    FortressBuilding.create!(
      world_fortress: fortress, building_key: "laboratory", name: "Лаборатория", level: 1
    )

    expect(described_class.unlocked?(character)).to be(true)
  end

  it "stays locked without clan membership" do
    expect(described_class.unlocked?(character)).to be(false)
  end
end
