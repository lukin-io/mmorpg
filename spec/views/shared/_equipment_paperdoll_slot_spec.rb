# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_equipment_paperdoll_slot.html.erb", type: :view do
  let(:slot) { EquipmentSlots::LEFT.find { |entry| entry.key == "main_hand" } }
  let(:template) { build_stubbed(:item_template, key: "penknife", name: "Penknife", durability_max: 10) }
  let(:item) { build_stubbed(:inventory_item, :equipped, item_template: template, properties: {"current_durability" => 10}) }

  [true, false].each do |interactive|
    it "renders the item's artwork in the #{interactive ? 'interactive inventory' : 'read-only player'} slot" do
      render partial: "shared/equipment_paperdoll_slot", locals: {slot:, equipment: {"main_hand" => item}, interactive:}

      cell = Nokogiri::HTML.fragment(rendered).at_css(".nl-doll-slot--main_hand")
      image = cell.at_css("img.nl-doll-slot-artwork")
      expect(image["src"]).to eq(view.image_path("items/penknife.png"))
      expect(image["alt"]).to eq("Penknife")
      expect(cell["style"]).to eq("--nl-slot-w: #{slot.width}px; --nl-slot-h: #{slot.height}px")
      expect(cell["title"]).to include("Penknife", "Durability: 10/10")
      expect(cell.name).to eq(interactive ? "button" : "span")
      expect(cell["aria-label"]).to eq("Remove Penknife from Weapon") if interactive
    end
  end

  it "keeps the named slot fallback for items without authored artwork" do
    template.key = "uncaptured_knife"
    render partial: "shared/equipment_paperdoll_slot", locals: {slot:, equipment: {"main_hand" => item}, interactive: true}

    expect(rendered).to have_css(".nl-doll-slot-name", text: "Penknife")
    expect(rendered).not_to have_css("img.nl-doll-slot-artwork")
    expect(rendered).to have_css("button[aria-label='Remove Penknife from Weapon']")
  end

  it "renders escaped NPC equipment without inventory controls or invented durability" do
    npc_equipment = {"main_hand" => {"name" => "Orc <Dagger>", "artwork" => "orc_dagger", "properties" => ["Attack: 1-2"]}}
    render partial: "shared/equipment_paperdoll_slot", locals: {slot:, equipment: {}, npc_equipment:, interactive: false}

    cell = Nokogiri::HTML.fragment(rendered).at_css(".nl-doll-slot--main_hand")
    expect(cell.at_css("img")["src"]).to eq(view.image_path("npc/equipment/orc_dagger.png"))
    expect(cell["title"]).to include("Orc <Dagger>", "Attack: 1-2")
    expect(rendered).not_to include("<Dagger>", "Durability:", "<button", "<form")
  end
end
