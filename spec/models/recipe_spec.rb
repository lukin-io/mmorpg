# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recipe, type: :model do
  describe "associations" do
    it "belongs to a profession" do
      recipe = build(:recipe)
      expect(recipe).to respond_to(:profession)
    end

    it "has many crafting jobs" do
      recipe = create(:recipe)
      expect(recipe).to respond_to(:crafting_jobs)
    end
  end

  describe "validations" do
    subject { build(:recipe) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "requires a tier" do
      subject.tier = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:tier]).to include("can't be blank")
    end

    it "requires duration_seconds" do
      subject.duration_seconds = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:duration_seconds]).to include("can't be blank")
    end

    it "requires output_item_name" do
      subject.output_item_name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:output_item_name]).to include("can't be blank")
    end

    it "requires premium_token_cost to be non-negative" do
      subject.premium_token_cost = -1
      expect(subject).not_to be_valid
      expect(subject.errors[:premium_token_cost]).to include("must be greater than or equal to 0")
    end
  end

  describe "enums" do
    it "defines source_kind enum" do
      expect(described_class.source_kinds).to include(
        "quest" => "quest",
        "drop" => "drop",
        "vendor" => "vendor",
        "guild_research" => "guild_research",
        "tutorial" => "tutorial"
      )
    end

    it "defines risk_level enum" do
      expect(described_class.risk_levels).to include(
        "safe" => "safe",
        "moderate" => "moderate",
        "risky" => "risky"
      )
    end
  end

  describe "#materials" do
    context "when requirements contains materials" do
      let(:recipe) do
        create(:recipe, requirements: {
          "materials" => {"Iron Ore" => 3, "Coal" => 1},
          "skill_level" => 10
        })
      end

      it "returns the materials hash" do
        expect(recipe.materials).to eq({"Iron Ore" => 3, "Coal" => 1})
      end

      it "returns materials as a hash with item names as keys" do
        expect(recipe.materials.keys).to contain_exactly("Iron Ore", "Coal")
      end

      it "returns materials with quantities as values" do
        expect(recipe.materials["Iron Ore"]).to eq(3)
        expect(recipe.materials["Coal"]).to eq(1)
      end
    end

    context "when requirements has no materials key" do
      let(:recipe) do
        create(:recipe, requirements: {"skill_level" => 5})
      end

      it "returns an empty hash" do
        expect(recipe.materials).to eq({})
      end
    end

    context "when requirements is empty" do
      let(:recipe) do
        create(:recipe, requirements: {})
      end

      it "returns an empty hash" do
        expect(recipe.materials).to eq({})
      end
    end

    context "when materials is an empty hash" do
      let(:recipe) do
        create(:recipe, requirements: {"materials" => {}})
      end

      it "returns an empty hash" do
        expect(recipe.materials).to eq({})
      end
    end

    context "when iterating over materials" do
      let(:recipe) do
        create(:recipe, requirements: {
          "materials" => {"Iron Ingot" => 4, "Coal Chunk" => 1}
        })
      end

      it "can be iterated with item_name and quantity" do
        items = []
        recipe.materials.each do |item_name, quantity|
          items << {name: item_name, qty: quantity}
        end

        expect(items).to contain_exactly(
          {name: "Iron Ingot", qty: 4},
          {name: "Coal Chunk", qty: 1}
        )
      end
    end
  end

  describe "#required_skill_level" do
    context "when requirements contains skill_level" do
      let(:recipe) do
        create(:recipe, tier: 2, requirements: {"skill_level" => 15})
      end

      it "returns the specified skill level" do
        expect(recipe.required_skill_level).to eq(15)
      end
    end

    context "when requirements does not contain skill_level" do
      let(:recipe) do
        create(:recipe, tier: 3, requirements: {"materials" => {}})
      end

      it "returns tier * 10 as default" do
        expect(recipe.required_skill_level).to eq(30)
      end
    end

    context "when requirements is empty" do
      let(:recipe) do
        create(:recipe, tier: 5, requirements: {})
      end

      it "returns tier * 10 as default" do
        expect(recipe.required_skill_level).to eq(50)
      end
    end

    context "when skill_level is 0" do
      let(:recipe) do
        create(:recipe, tier: 1, requirements: {"skill_level" => 0})
      end

      it "returns 0" do
        expect(recipe.required_skill_level).to eq(0)
      end
    end

    context "with various tier levels" do
      [1, 2, 3, 4, 5].each do |tier|
        it "defaults to #{tier * 10} for tier #{tier}" do
          recipe = create(:recipe, tier: tier, requirements: {})
          expect(recipe.required_skill_level).to eq(tier * 10)
        end
      end
    end
  end

  describe "#requires_premium_tokens?" do
    context "when premium_token_cost is positive" do
      let(:recipe) { create(:recipe, premium_token_cost: 5) }

      it "returns true" do
        expect(recipe.requires_premium_tokens?).to be true
      end
    end

    context "when premium_token_cost is zero" do
      let(:recipe) { create(:recipe, premium_token_cost: 0) }

      it "returns false" do
        expect(recipe.requires_premium_tokens?).to be false
      end
    end
  end

  describe "#risky?" do
    context "when risk_level is risky" do
      let(:recipe) { create(:recipe, risk_level: "risky") }

      it "returns true" do
        expect(recipe.risky?).to be true
      end
    end

    context "when risk_level is safe" do
      let(:recipe) { create(:recipe, risk_level: "safe") }

      it "returns false" do
        expect(recipe.risky?).to be false
      end
    end

    context "when risk_level is moderate" do
      let(:recipe) { create(:recipe, risk_level: "moderate") }

      it "returns false" do
        expect(recipe.risky?).to be false
      end
    end
  end

  describe "#guild_locked?" do
    context "when guild_bound is true" do
      let(:recipe) { create(:recipe, guild_bound: true) }

      it "returns true" do
        expect(recipe.guild_locked?).to be true
      end
    end

    context "when guild_bound is false" do
      let(:recipe) { create(:recipe, guild_bound: false) }

      it "returns false" do
        expect(recipe.guild_locked?).to be false
      end
    end
  end

  describe "#success_penalty" do
    context "when requirements contains success_penalty" do
      let(:recipe) do
        create(:recipe, requirements: {"success_penalty" => 10})
      end

      it "returns the specified penalty" do
        expect(recipe.success_penalty).to eq(10)
      end
    end

    context "when requirements does not contain success_penalty" do
      let(:recipe) do
        create(:recipe, requirements: {})
      end

      it "returns 0 as default" do
        expect(recipe.success_penalty).to eq(0)
      end
    end

    context "when success_penalty is a string" do
      let(:recipe) do
        create(:recipe, requirements: {"success_penalty" => "5"})
      end

      it "converts to integer" do
        expect(recipe.success_penalty).to eq(5)
      end
    end
  end

  describe "bug regression: required_skill_level method existence" do
    # This test ensures the required_skill_level method exists and works
    # Previously this method was missing, causing NoMethodError in views

    let(:recipe) { create(:recipe, tier: 2, requirements: {"skill_level" => 25}) }

    it "responds to required_skill_level" do
      expect(recipe).to respond_to(:required_skill_level)
    end

    it "returns the skill level from requirements" do
      expect(recipe.required_skill_level).to eq(25)
    end
  end

  describe "bug regression: materials hash format" do
    # This test ensures materials returns a hash with {name => quantity} format
    # Previously the view assumed an array of hashes with :name and :quantity keys

    let(:recipe) do
      create(:recipe, requirements: {
        "materials" => {"Iron Ingot" => 4, "Coal Chunk" => 1}
      })
    end

    it "materials is a hash, not an array" do
      expect(recipe.materials).to be_a(Hash)
    end

    it "materials keys are item names (strings)" do
      recipe.materials.keys.each do |key|
        expect(key).to be_a(String)
      end
    end

    it "materials values are quantities (integers)" do
      recipe.materials.values.each do |value|
        expect(value).to be_a(Integer)
      end
    end

    it "can be safely iterated with |item_name, quantity| block params" do
      result = []
      expect {
        recipe.materials.each do |item_name, quantity|
          result << "#{item_name} x#{quantity}"
        end
      }.not_to raise_error
      expect(result).not_to be_empty
    end
  end
end
