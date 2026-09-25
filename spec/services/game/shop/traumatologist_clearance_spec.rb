# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Shop::TraumatologistClearance do
  let(:character) { create(:character, perks: {"healer" => true}) }
  let(:service) { described_class.new(character:) }

  it "is visible with Healer and incomplete until clearance" do
    expect(service.visible?).to be(true)
    expect(service.completed?).to be(false)
  end

  it "rejects characters without Healer unchanged" do
    character.update!(perks: {})

    result = service.call

    expect(result.success).to be(false)
    expect(result.message).to eq(I18n.t("game.shop.healer_perk_required"))
    expect(character.reload.metadata["profession_unlocks"]).to be_nil
  end

  it "sets the traumatologist unlock once and stays idempotent" do
    first = service.call
    expect(first.success).to be(true)
    expect(first.message).to eq(I18n.t("game.shop.traumatologist_completed"))
    expect(character.reload.metadata.dig("profession_unlocks", "traumatologist")).to be(true)

    second = described_class.new(character: character.reload).call
    expect(second.success).to be(true)
    expect(second.message).to eq(I18n.t("game.shop.traumatologist_already_done"))
    expect(character.reload.metadata.dig("profession_unlocks", "traumatologist")).to be(true)
  end

  it "rejects while the character is in combat" do
    character.update!(in_combat: true)

    result = service.call

    expect(result.success).to be(false)
    expect(result.message).to eq(I18n.t("game.buildings.hospital_in_combat"))
    expect(character.reload.metadata["profession_unlocks"]).to be_nil
  end

  it "unblocks Doctor II purchase after clearance" do
    rules = Game::Shop::LicenseRules.new(character:)
    template = build(:item_template, stack_limit: 1, enhancement_rules: {"license" => {
      "kind" => "doctor", "tier" => 2, "duration_days" => Game::Shop::LicenseRules::DURATIONS.fetch("doctor")[1]
    }})

    expect(rules.purchase_block_reason(template)).to eq(I18n.t("game.shop.traumatologist_quest_required"))
    expect(service.call.success).to be(true)
    expect(rules.purchase_block_reason(template)).to be_nil
  end
end
