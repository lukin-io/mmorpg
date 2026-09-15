# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerProfileHelper, type: :helper do
  it "shows the same mastered attack cost and total item armor as the fight engine" do
    character = create(:character, passive_skills: {"bludgeoning_mastery" => 100})
    weapon = create(:item_template, slot: "main_hand", requirements: {"ap" => 72},
      stat_modifiers: {"weapon_family" => "blunt", "bludgeoning_mastery" => 50, "defense" => 12})
    create(:inventory_item, :equipped, inventory: character.inventory, item_template: weapon)
    expect(helper.profile_combat_stats(character)).to include("AP per strike" => 62, "Armor class" => 12)
    expect(character.arena_participations).to be_empty
  end
end
