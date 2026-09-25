# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Clans::Create do
  let(:character) { create(:character) }

  it "creates a light-side clan with leader membership" do
    result = described_class.new(
      character:,
      name: "Пепельные Стражи",
      tag: "ASH",
      alignment: "light",
      require_clan_hall: false
    ).call

    expect(result.success).to eq(true), -> { result.message }
    expect(result.clan.alignment).to eq("light")
    expect(character.reload.clan_membership.role).to eq("leader")
    expect(result.clan.treasury_locked?).to eq(true)
  end

  it "rejects creation without clan hall when required" do
    result = described_class.new(
      character:,
      name: "Тест",
      tag: "ZZZ",
      alignment: "dark",
      require_clan_hall: true
    ).call

    expect(result.success).to eq(false)
  end
end

RSpec.describe Game::Clans::TreasuryTransfer do
  let(:leader) { create(:character) }
  let(:clan) do
    Game::Clans::Create.new(
      character: leader,
      name: "Казна Тест",
      tag: "TRE",
      alignment: "dark",
      require_clan_hall: false
    ).call.clan
  end

  before { clan }

  it "accepts NV donations from members" do
    wallet = leader.user.currency_wallet || leader.user.create_currency_wallet!(nv_balance: 0)
    wallet.update!(nv_balance: 100)

    result = described_class.new(actor: leader, action: "donate_nv", amount_nv: 25).call
    expect(result.success).to eq(true), -> { result.message }
    expect(clan.reload.treasury_nv.to_i).to eq(25)
  end

  it "blocks worker withdraw while locked" do
    worker = create(:character)
    ClanMembership.create!(clan:, character: worker, role: "worker", joined_at: Time.current)
    clan.update!(treasury_nv: 50, treasury_locked: true)

    result = described_class.new(actor: worker, action: "withdraw_nv", amount_nv: 10).call
    expect(result.success).to eq(false)
  end
end
