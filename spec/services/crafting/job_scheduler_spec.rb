require "rails_helper"

RSpec.describe Crafting::JobScheduler do
  it "queues a job when requirements met" do
    user = create(:user)
    profession = create(:profession)
    create(:profession_progress, user:, profession:, skill_level: 5)
    recipe = create(:recipe, profession:, requirements: {"skill_level" => 3})
    station = create(:crafting_station)

    job = described_class.new(user:, recipe:, station:).enqueue!

    expect(job).to be_queued
  end
end
