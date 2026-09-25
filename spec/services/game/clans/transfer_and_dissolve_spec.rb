# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Clans::TransferLeadership do
  let(:leader) { create(:character) }
  let(:successor) { create(:character) }
  let(:clan) do
    Game::Clans::Create.new(
      character: leader,
      name: "Передача",
      tag: "XFR",
      alignment: "light",
      require_clan_hall: false
    ).call.clan
  end

  before do
    clan
    ClanMembership.create!(clan:, character: successor, role: "worker", joined_at: Time.current)
  end

  it "moves leadership and demotes former leader to deputy" do
    result = described_class.new(actor: leader, successor_character_id: successor.id).call
    expect(result.success).to eq(true), -> { result.message }
    expect(clan.reload.leader_character_id).to eq(successor.id)
    expect(successor.reload.clan_membership.role).to eq("leader")
    expect(leader.reload.clan_membership.role).to eq("deputy")
  end
end

RSpec.describe Game::Clans::Dissolve do
  let(:leader) { create(:character) }
  let(:clan) do
    Game::Clans::Create.new(
      character: leader,
      name: "Роспуск",
      tag: "DIS",
      alignment: "dark",
      require_clan_hall: false
    ).call.clan
  end

  before { clan }

  it "destroys the clan and clears membership" do
    result = described_class.new(actor: leader).call
    expect(result.success).to eq(true), -> { result.message }
    expect(Clan.find_by(id: clan.id)).to be_nil
    expect(leader.reload.clan_membership).to be_nil
  end
end
