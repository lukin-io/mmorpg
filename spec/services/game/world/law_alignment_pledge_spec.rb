# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::LawAlignmentPledge do
  let(:character) { create(:character, alignment: "none") }

  before do
    character.user.currency_wallet.update!(nv_balance: 40)
  end

  it "pledges the first alignment for free" do
    result = described_class.new(character:, alignment: "law").call

    expect(result.success).to be(true)
    expect(character.reload.alignment).to eq("law")
    expect(character.user.currency_wallet.reload.nv_balance).to eq(40)
  end

  it "charges NV to change an existing alignment" do
    character.update!(alignment: "law")

    result = described_class.new(character:, alignment: "chaos").call

    expect(result.success).to be(true)
    expect(character.reload.alignment).to eq("chaos")
    expect(character.user.currency_wallet.reload.nv_balance).to eq(15)
  end

  it "rejects unknown alignments" do
    expect(described_class.new(character:, alignment: "void").call.success).to be(false)
  end
end
