require "rails_helper"

RSpec.describe Crafting::JobScheduler do
  let(:user) { create(:user, premium_tokens_balance: 100) }
  let(:character) { create(:character, user:) }
  let(:profession) { create(:profession) }
  let!(:progress) { create(:profession_progress, character:, profession:, skill_level: 5) }
  let!(:tool) { create(:profession_tool, character:, profession:) }
  let(:recipe) { create(:recipe, profession:, requirements: {"skill_level" => 3}) }
  let(:station) { create(:crafting_station, capacity: 2) }

  before do
    progress.update!(equipped_tool: tool)
  end

  it "queues multiple jobs respecting quantity" do
    jobs = described_class.new(user:, character:, recipe:, station:).enqueue!(quantity: 2)

    expect(jobs.size).to eq(2)
    expect(jobs.first.character).to eq(character)
    expect(jobs.first.recipe).to eq(recipe)
  end

  it "queues a job when requirements met" do
    jobs = described_class.new(user:, character:, recipe:, station:).enqueue!

    expect(jobs.first).to be_queued
  end
end
