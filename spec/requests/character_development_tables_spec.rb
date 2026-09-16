# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Source development tables", type: :request do
  let(:user) { create(:user) }
  let!(:character) { create(:character, user:, perk_points: 2) }

  before { sign_in user, scope: :user }

  it "renders all categories while restricting selection to implemented perks" do
    get perks_character_path(character)
    doc = Nokogiri::HTML(response.body)
    expect(doc.css(".nl-perk-row").size).to eq(42)
    expect(doc.css(".nl-skill-category-header").map(&:text)).to contain_exactly("Professions", "Auxiliary Perks", "Stat Perks", "Resistances", "Magic Perks", "Warrior Perks")
    expect(doc.css("input[name^='selected_perks']").size).to eq(4)
    expect(doc.css(".nl-perk-unavailable").size).to eq(38)
    expect(response.body).not_to include("Source #")
    patch perks_character_path(character), params: {selected_perks: {more_health: "1"}}
    expect(character.reload.perk_points).to eq(2)
    expect(character.perks).not_to have_key("more_health")
  end

  it "renders learned skills, equipment bonuses and separate uncapped profession counters" do
    character.update!(passive_skills: {"knife_mastery" => 100}, metadata: {"profession_skills" => {"doctor" => 601, "trading" => -2, "fishing" => 10001, "hunting" => "forged"}})
    template = create(:item_template, stat_modifiers: {"knife_skill" => 30, "doctor" => 10})
    create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true)
    get skills_character_path(character)
    doc = Nokogiri::HTML(response.body)
    expect(doc.css(".nl-profession-row").size).to eq(15)
    row = doc.at_css("[data-skill-row='knife_mastery']")
    expect(row.at_css(".nl-skill-value").text).to include("[100/100]")
    expect(row.at_css(".nl-skill-equipment-bonus").text).to include("+30")
    expect(doc.at_css("[data-profession='doctor']").text).to include("[0601]", "+10")
    expect(doc.at_css("[data-profession='fishing']").text).to include("[10001]")
    %w[trading hunting].each { |key| expect(doc.at_css("[data-profession='#{key}']").text).to include("[0000]") }
    expect(doc.css(".nl-profession-row input, .nl-profession-row button")).to be_empty
  end
end
