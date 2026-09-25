# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Inventory::RequirementChecker do
  let(:character) { create(:character, level: 1, allocated_stats: {"strength" => 1}) }
  let(:inventory) { character.inventory }

  def item_with_requirements(requirements)
    template = create(:item_template, requirements:)
    create(:inventory_item, inventory:, item_template: template)
  end

  it "localizes missing requirement names instead of English titleize" do
    item = item_with_requirements("strength" => 99, "level" => 50)

    I18n.with_locale(:ru) do
      result = described_class.call(character:, item:)

      expect(result[:allowed]).to eq(false)
      labels = result[:missing].map { |entry| entry[:label] }.join(" ")
      expect(labels).to include(I18n.t("game.details.strength"))
      expect(labels).to include(I18n.t("game.details.level"))
      expect(labels).not_to match(/Strength|Level/)
    end
  end

  it "allows items when requirements are met" do
    item = item_with_requirements("level" => 1)

    result = described_class.call(character:, item:)

    expect(result).to eq(allowed: true, missing: [])
  end
end
