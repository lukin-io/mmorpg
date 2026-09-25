# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::Journal do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:journal) { described_class.new(character:) }

  before do
    Game::Quests::Catalog.reload!
  end

  def complete!(quest_key)
    character.with_lock do
      character.reload
      bag = character.metadata.to_h.fetch("ashen_quests", {})
      bag = bag.merge(quest_key.to_s => {
        "status" => "completed",
        "progress" => 1,
        "completed_at" => Time.current.iso8601
      })
      character.update!(metadata: character.metadata.to_h.merge("ashen_quests" => bag))
    end
  end

  it "accepts a starter quest into character metadata" do
    result = journal.accept!("veil_lure_drill")

    expect(result.success).to eq(true)
    state = character.reload.metadata.dig("ashen_quests", "veil_lure_drill")
    expect(state["status"]).to eq("active")
    expect(state["progress"]).to eq(0)
  end

  it "locks chain quests until requirements are completed" do
    result = journal.accept!("veil_tail_delivery")

    expect(result.success).to eq(false)
    expect(result.message).to include(I18n.t("game.quests.locked"))
    expect(journal.present(Game::Quests::Catalog.find("veil_tail_delivery"))[:status]).to eq("locked")
  end

  it "accepts the Ash Healer first-bag delivery after Tar Smith bandage" do
    complete!("veil_lure_drill")
    complete!("veil_tail_delivery")
    complete!("tar_smith_first_bandage")

    result = journal.accept!("ash_healer_first_bag")

    expect(result.success).to eq(true)
    state = character.reload.metadata.dig("ashen_quests", "ash_healer_first_bag")
    expect(state["status"]).to eq("active")
    expect(Game::Quests::Catalog.find("ash_healer_first_bag").dig("objective", "item_key")).to eq("healer_bag_light")
  end

  it "turns in the Ash Healer first bag and grants ash_herb reward" do
    Game::Professions::Templates.ensure_craft_items!
    complete!("veil_lure_drill")
    complete!("veil_tail_delivery")
    complete!("tar_smith_first_bandage")
    journal.accept!("ash_healer_first_bag")
    Game::Inventory::Manager.new(inventory: character.inventory).add_item!(
      item_template: ItemTemplate.find_by!(key: "healer_bag_light"),
      quantity: 1
    )
    wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
    before_nv = wallet.nv_balance.to_i
    before_herb = character.inventory.inventory_items.joins(:item_template)
      .where(item_templates: {key: "ash_herb"}, equipped: false).sum(:quantity)

    result = journal.turn_in!("ash_healer_first_bag")

    expect(result.success).to eq(true)
    state = character.reload.metadata.dig("ashen_quests", "ash_healer_first_bag")
    expect(state["status"]).to eq("completed")
    expect(wallet.reload.nv_balance.to_i).to eq(before_nv + 30)
    expect(character.inventory.inventory_items.joins(:item_template)
      .where(item_templates: {key: "healer_bag_light"}, equipped: false).sum(:quantity)).to eq(0)
    expect(character.inventory.inventory_items.joins(:item_template)
      .where(item_templates: {key: "ash_herb"}, equipped: false).sum(:quantity)).to eq(before_herb + 1)
  end

  it "auto-unlocks the next contract on turn-in" do
    Game::Professions::Templates.ensure_craft_items!
    journal.accept!("veil_lure_drill")
    character.with_lock do
      character.reload
      bag = character.metadata.to_h.fetch("ashen_quests", {})
      bag = bag.merge("veil_lure_drill" => bag.fetch("veil_lure_drill").merge("progress" => 1))
      character.update!(metadata: character.metadata.to_h.merge("ashen_quests" => bag))
    end

    result = journal.turn_in!("veil_lure_drill")

    expect(result.success).to eq(true)
    expect(result.message).to match(/Открыто следом|Unlocked next/)
    tail = character.reload.metadata.dig("ashen_quests", "veil_tail_delivery")
    expect(tail["status"]).to eq("active")
  end

  it "includes where-hint on active chip" do
    journal.accept!("veil_lure_drill")
    chip = journal.active_chip

    expect(chip).to include("1")
    expect(chip).to match(/Западные ворота|West Gate/)
  end

  it "shows live delivery progress from inventory" do
    complete!("veil_lure_drill")
    journal.accept!("veil_tail_delivery")
    Game::Professions::Templates.instance_variable_set(:@craft_items_ensured, false)
    Game::Professions::Templates.ensure_craft_items!
    Game::Inventory::Manager.new(inventory: character.inventory).add_item!(
      item_template: ItemTemplate.find_by!(key: "rat_tail"),
      quantity: 1
    )

    entry = journal.present(Game::Quests::Catalog.find("veil_tail_delivery"))
    expect(entry[:progress]).to eq(1)
    expect(entry[:target]).to eq(1)
  end

  it "counts av_* farm kills toward shore kill_npc objectives" do
    journal.accept!("veil_lure_drill")
    quest = Game::Quests::Catalog.find("veil_lure_drill")
    keys = Array(quest.dig("objective", "npc_keys")).map(&:to_s)
    shore = keys.first
    skip "no kill keys" if shore.blank?

    journal.record_npc_kill!(npc_key: "av_#{shore}")
    state = character.reload.metadata.dig("ashen_quests", "veil_lure_drill")
    expect(state["progress"].to_i).to be >= 1
  end
end
