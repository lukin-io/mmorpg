# frozen_string_literal: true

require "rails_helper"

RSpec.describe CraftingJobsHelper, type: :helper do
  describe "PROFESSION_ICONS" do
    it "defines icons for standard professions" do
      expect(described_class::PROFESSION_ICONS).to include(
        "blacksmithing" => "⚒️",
        "tailoring" => "🧵",
        "alchemy" => "⚗️",
        "cooking" => "🍳",
        "enchanting" => "✨",
        "herbalism" => "🌿",
        "mining" => "⛏️",
        "fishing" => "🎣",
        "medical" => "💊"
      )
    end

    it "is frozen to prevent modification" do
      expect(described_class::PROFESSION_ICONS).to be_frozen
    end
  end

  describe "#crafting_job_icon" do
    let(:profession) { create(:profession, name: profession_name) }
    let(:recipe) { create(:recipe, profession: profession) }
    let(:crafting_job) { create(:crafting_job, recipe: recipe) }

    context "when profession has a known icon" do
      let(:profession_name) { "Blacksmithing" }

      it "returns the correct icon for blacksmithing" do
        expect(helper.crafting_job_icon(crafting_job)).to eq("⚒️")
      end
    end

    context "when profession name is lowercase" do
      let(:profession_name) { "alchemy" }

      it "returns the correct icon" do
        expect(helper.crafting_job_icon(crafting_job)).to eq("⚗️")
      end
    end

    context "when profession name is mixed case" do
      let(:profession_name) { "HeRbAlIsM" }

      it "normalizes to lowercase and returns the correct icon" do
        expect(helper.crafting_job_icon(crafting_job)).to eq("🌿")
      end
    end

    context "when profession has no defined icon" do
      let(:profession_name) { "UnknownProfession" }

      it "returns the default package icon" do
        expect(helper.crafting_job_icon(crafting_job)).to eq("📦")
      end
    end

    context "with all known profession types" do
      {
        "Blacksmithing" => "⚒️",
        "Tailoring" => "🧵",
        "Alchemy" => "⚗️",
        "Cooking" => "🍳",
        "Enchanting" => "✨",
        "Herbalism" => "🌿",
        "Mining" => "⛏️",
        "Fishing" => "🎣",
        "Medical" => "💊"
      }.each do |name, expected_icon|
        it "returns #{expected_icon} for #{name}" do
          profession = create(:profession, name: name)
          recipe = create(:recipe, profession: profession)
          job = create(:crafting_job, recipe: recipe)

          expect(helper.crafting_job_icon(job)).to eq(expected_icon)
        end
      end
    end
  end

  describe "#recipe_icon" do
    let(:profession) { create(:profession, name: profession_name) }
    let(:recipe) { create(:recipe, profession: profession) }

    context "when profession has a known icon" do
      let(:profession_name) { "Alchemy" }

      it "returns the correct icon for alchemy" do
        expect(helper.recipe_icon(recipe)).to eq("⚗️")
      end
    end

    context "when profession name is uppercase" do
      let(:profession_name) { "COOKING" }

      it "normalizes to lowercase and returns the correct icon" do
        expect(helper.recipe_icon(recipe)).to eq("🍳")
      end
    end

    context "when profession name has spaces" do
      let(:profession_name) { "Unknown Profession" }

      it "returns the default package icon" do
        expect(helper.recipe_icon(recipe)).to eq("📦")
      end
    end

    context "when profession is nil" do
      it "raises an error" do
        recipe_without_profession = build(:recipe)
        recipe_without_profession.profession = nil

        expect { helper.recipe_icon(recipe_without_profession) }.to raise_error(NoMethodError)
      end
    end

    context "with all known profession types" do
      {
        "blacksmithing" => "⚒️",
        "tailoring" => "🧵",
        "alchemy" => "⚗️",
        "cooking" => "🍳",
        "enchanting" => "✨",
        "herbalism" => "🌿",
        "mining" => "⛏️",
        "fishing" => "🎣",
        "medical" => "💊"
      }.each do |name, expected_icon|
        it "returns #{expected_icon} for #{name}" do
          profession = create(:profession, name: name)
          recipe = create(:recipe, profession: profession)

          expect(helper.recipe_icon(recipe)).to eq(expected_icon)
        end
      end
    end
  end

  describe "bug regression: profession.key vs profession.name" do
    # This test ensures we don't regress to using .key which doesn't exist on Profession
    let(:profession) { create(:profession, name: "Blacksmithing") }
    let(:recipe) { create(:recipe, profession: profession) }
    let(:crafting_job) { create(:crafting_job, recipe: recipe) }

    it "uses profession.name (not profession.key) in crafting_job_icon" do
      # Profession doesn't have a .key method, so this should work
      expect(profession).to respond_to(:name)
      expect(profession).not_to respond_to(:key)
      expect { helper.crafting_job_icon(crafting_job) }.not_to raise_error
    end

    it "uses profession.name (not profession.key) in recipe_icon" do
      expect { helper.recipe_icon(recipe) }.not_to raise_error
    end
  end
end
