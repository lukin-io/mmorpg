# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::JoinAsProtector do
  let(:zone) { create(:zone, name: "Intervention Field", location_type: "outdoor") }
  let(:fighter_a) { create(:character, name: "SideA", current_hp: 80, max_hp: 100) }
  let(:fighter_b) { create(:character, name: "SideB", current_hp: 80, max_hp: 100) }
  let(:protector) { create(:character, name: "Protector", current_hp: 100, max_hp: 100) }
  let!(:match) do
    create(:arena_match, :live, zone:, trauma_percent: 40, metadata: {"assault_scroll_kind" => "normal"})
  end

  before do
    create(:arena_participation, arena_match: match, character: fighter_a, user: fighter_a.user, team: "a")
    create(:arena_participation, arena_match: match, character: fighter_b, user: fighter_b.user, team: "b")
    Game::Professions::Templates.ensure_craft_items!
    template = ItemTemplate.find_by!(key: "protection_scroll")
    Game::Inventory::Manager.new(inventory: protector.inventory).add_item!(item_template: template, quantity: 1)
  end

  it "consumes the protection scroll and joins a live fight on the chosen team" do
    result = described_class.new(character: protector, match_id: match.id, team: "b").call

    expect(result.success).to be(true)
    participation = match.arena_participations.find_by!(character: protector)
    expect(participation.team).to eq("b")
    expect(participation.metadata["protector"]).to eq(true)
    expect(protector.reload.in_combat).to be(true)
    expect(
      protector.inventory.inventory_items.joins(:item_template)
        .where(item_templates: {key: "protection_scroll"}).sum(:quantity)
    ).to eq(0)
  end

  it "rejects join without a protection scroll" do
    template = ItemTemplate.find_by!(key: "protection_scroll")
    Game::Inventory::Manager.new(inventory: protector.inventory).remove_item!(item_template: template, quantity: 1)

    expect {
      result = described_class.new(character: protector, match_id: match.id, team: "a").call
      expect(result.success).to be(false)
    }.not_to change { match.arena_participations.count }
  end
end
