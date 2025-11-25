# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::RewardService do
  let(:character) { create(:character, reputation: 0) }
  let(:skill_node) { create(:skill_node, key: "luminous_strike") }
  let(:profession) { create(:profession, name: "Armorsmith") }
  let(:rewards) do
    {
      "xp" => 500,
      "currency" => {"gold" => 120},
      "reputation" => 15,
      "recipes" => ["sunsteel_ingot"],
      "cosmetics" => ["heroic_cloak"],
      "premium_tokens" => 3,
      "class_abilities" => [skill_node.key],
      "profession_unlocks" => [profession.name],
      "housing_upgrades" => 2
    }
  end
  let(:quest) { create(:quest, rewards:) }
  let(:assignment) { create(:quest_assignment, quest:, character:, status: :completed) }

  let(:xp_instance) { instance_double("Players::Progression::ExperiencePipeline", grant!: nil) }
  let(:xp_class) { double("Players::Progression::ExperiencePipeline", new: xp_instance) }
  let(:wallet_instance) { instance_double("Economy::WalletService", adjust!: nil) }
  let(:wallet_class) { double("Economy::WalletService", new: wallet_instance) }
  let(:expander_instance) { instance_double("Game::Inventory::ExpansionService", expand!: nil) }
  let(:expander_class) { double("Game::Inventory::ExpansionService", new: expander_instance) }

  describe "#claim!" do
    it "applies the structured reward payload and records metadata" do
      result = described_class.new(
        assignment:,
        experience_pipeline: xp_class,
        wallet_service: wallet_class,
        inventory_expander: expander_class
      ).claim!

      expect(result.assignment).to eq(assignment)
      expect(result.applied[:xp]).to eq(500)
      expect(xp_instance).to have_received(:grant!).with(hash_including("quest" => 500))
      expect(wallet_instance).to have_received(:adjust!).with(hash_including(currency: "gold", amount: 120))
      expect(wallet_instance).to have_received(:adjust!).with(hash_including(currency: :premium_tokens, amount: 3))
      expect(character.reload.reputation).to eq(15)
      expect(character.metadata["recipe_keys"]).to include("sunsteel_ingot")
      expect(character.metadata["cosmetic_keys"]).to include("heroic_cloak")
      expect(character.character_skills.exists?(skill_node:)).to be(true)
      expect(character.profession_progresses.exists?(profession:)).to be(true)
      expect(expander_instance).to have_received(:expand!).twice
      expect(assignment.reload.rewards_claimed_at).to be_present
      expect(assignment.metadata["last_reward"]["xp"]).to eq(500)
    end

    it "raises when rewards were already claimed" do
      assignment.update!(rewards_claimed_at: 1.day.ago)

      service = described_class.new(
        assignment:,
        experience_pipeline: xp_class,
        wallet_service: wallet_class,
        inventory_expander: expander_class
      )

      expect { service.claim! }.to raise_error(described_class::AlreadyClaimedError)
    end
  end
end
