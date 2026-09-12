# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Skill allocation with equipment", type: :request do
  let(:user) { create(:user) }
  let!(:character) do
    create(:character, user:, combat_skill_points: 2, passive_skills: {"knife_mastery" => 98})
  end

  before do
    sign_in user, scope: :user
    create(:character_position, character:)
    template = create(:item_template, stat_modifiers: {"knife_skill" => 30})
    create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)
  end

  it "renders effective totals while previewing and enabling allocation from learned levels" do
    get skills_character_path(character)

    expect(response).to have_http_status(:success)
    document = Nokogiri::HTML(response.body)
    panel = document.at_css('[data-controller="skill-allocation"]')
    row = document.at_css('[data-skill="knife_mastery"]').ancestors(".nl-skill-row").first

    expect(JSON.parse(panel["data-skill-allocation-skills-value"])["knife_mastery"]).to eq(98)
    expect(JSON.parse(panel["data-skill-allocation-equipment-bonuses-value"])["knife_mastery"]).to eq(30)
    expect(row.at_css(".nl-skill-value").text).to include("[128/100]")
    expect(row.at_css(".nl-skill-gain").text.strip).to eq("+2")
    expect(row.at_css(".nl-stat-btn--plus")["disabled"]).to be_nil
    expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(98)
  end

  it "renders capped learned skills with effective totals above 100" do
    character.update!(passive_skills: {"knife_mastery" => 100, "bludgeoning_mastery" => 100})
    template = create(:item_template, stat_modifiers: {"bludgeoning_mastery" => 50})
    create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)

    get skills_character_path(character)

    expect(response).to have_http_status(:success)
    document = Nokogiri::HTML(response.body)
    {"knife_mastery" => 130, "bludgeoning_mastery" => 150}.each do |skill, effective|
      row = document.at_css("[data-skill='#{skill}']").ancestors(".nl-skill-row").first
      expect(row.at_css(".nl-skill-value").text).to include("[#{effective}/100]")
      expect(row.at_css(".nl-skill-gain").text.strip).to eq("MAX")
      expect(row.at_css(".nl-stat-btn--plus")["disabled"]).not_to be_nil
    end
  end

  it "returns a Turbo allocation result without passing an effective total into the tier formula" do
    patch skills_character_path(character), params: {allocated_skills: {knife_mastery: 2}},
      headers: {"ACCEPT" => "text/vnd.turbo-stream.html"}

    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(character.reload.base_passive_skill_level(:knife_mastery)).to eq(100)
    expect(character.passive_skill_level(:knife_mastery)).to eq(130)
    expect(character.combat_skill_points).to eq(1)
    document = Nokogiri::HTML(response.body)
    panel = document.at_css('[data-controller="skill-allocation"]')
    expect(JSON.parse(panel["data-skill-allocation-skills-value"])["knife_mastery"]).to eq(100)
    expect(document.at_css('[data-skill="knife_mastery"]').text).to include("[130/100]")
  end
end
