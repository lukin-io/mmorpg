# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::StartPlayerAssault do
  let(:zone) { create(:zone, name: "Assault Woods", location_type: "outdoor") }
  let(:attacker) { create(:character, name: "AttackerAsh", level: 4, current_hp: 100, max_hp: 100) }
  let(:defender) { create(:character, name: "DefenderAsh", level: 4, current_hp: 100, max_hp: 100) }
  let!(:attacker_position) { create(:character_position, character: attacker, zone:, x: 3, y: 4) }
  let!(:defender_position) { create(:character_position, character: defender, zone:, x: 3, y: 4) }

  before do
    create(:user_session, user: attacker.user)
    create(:user_session, user: defender.user)
    Game::Professions::Templates.ensure_craft_items!
    template = ItemTemplate.find_by!(key: "combat_trauma_scroll")
    Game::Inventory::Manager.new(inventory: attacker.inventory).add_item!(item_template: template, quantity: 1)
  end

  it "consumes an assault scroll and starts a world PvP duel with scroll trauma metadata" do
    result = described_class.new(attacker:, defender_id: defender.id, assault_scroll_kind: "bloody").call

    expect(result.success).to be(true)
    expect(result.match).to be_live
    expect(result.match.metadata).to include(
      "source" => "world_pvp",
      "assault_scroll_kind" => "bloody",
      "combat_trauma" => true,
      "attacker_id" => attacker.id,
      "defender_id" => defender.id
    )
    expect(result.match.arena_participations.players.map(&:character_id)).to contain_exactly(attacker.id, defender.id)
    expect(
      attacker.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "combat_trauma_scroll"}).sum(:quantity)
    ).to eq(0)
  end

  it "rejects assault without a trauma scroll and leaves state unchanged" do
    template = ItemTemplate.find_by!(key: "combat_trauma_scroll")
    Game::Inventory::Manager.new(inventory: attacker.inventory).remove_item!(item_template: template, quantity: 1)

    expect {
      result = described_class.new(attacker:, defender_id: defender.id).call
      expect(result.success).to be(false)
      expect(result.message).to eq(I18n.t("arena.combat_scroll_missing"))
    }.not_to change(ArenaMatch, :count)
  end

  it "rejects assault when the defender is on another cell" do
    defender_position.update!(x: 9, y: 9)

    result = described_class.new(attacker:, defender_id: defender.id).call

    expect(result.success).to be(false)
    expect(result.message).to eq(I18n.t("game.world.assault_not_nearby"))
  end

  it "rejects assault inside the hospital safe zone" do
    attacker.remember_gameplay_context!(name: "city_building", params: {building_key: "hospital"})
    defender.remember_gameplay_context!(name: "city_building", params: {building_key: "hospital"})

    result = described_class.new(attacker:, defender_id: defender.id).call

    expect(result.success).to be(false)
    expect(result.message).to eq(I18n.t("game.world.assault_safe_zone"))
  end

  it "reports offerable presence for colocated online players outside safe zones" do
    expect(described_class.offerable?(attacker:, defender:)).to be(true)
    expect(described_class.has_trauma_scroll?(attacker)).to be(true)

    defender_position.update!(x: 9, y: 9)
    expect(described_class.offerable?(attacker:, defender: defender.reload)).to be(false)
  end
end
