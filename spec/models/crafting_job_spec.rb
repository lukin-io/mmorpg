# frozen_string_literal: true

require "rails_helper"

RSpec.describe CraftingJob do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:profession) { create(:profession, name: "Blacksmithing") }
  let(:recipe) { create(:recipe, profession: profession) }
  let(:crafting_station) { create(:crafting_station) }

  let(:crafting_job) do
    create(:crafting_job,
      user: user,
      character: character,
      recipe: recipe,
      crafting_station: crafting_station,
      started_at: 1.hour.ago,
      completes_at: 1.hour.from_now)
  end

  describe "associations" do
    it "belongs to user" do
      expect(crafting_job.user).to eq(user)
    end

    it "belongs to character" do
      expect(crafting_job.character).to eq(character)
    end

    it "belongs to recipe" do
      expect(crafting_job.recipe).to eq(recipe)
    end

    it "belongs to crafting_station" do
      expect(crafting_job.crafting_station).to eq(crafting_station)
    end
  end

  describe "validations" do
    it "requires started_at" do
      job = build(:crafting_job, started_at: nil)
      expect(job).not_to be_valid
      expect(job.errors[:started_at]).to include("can't be blank")
    end

    it "requires completes_at" do
      job = build(:crafting_job, completes_at: nil)
      expect(job).not_to be_valid
      expect(job.errors[:completes_at]).to include("can't be blank")
    end

    it "requires batch_quantity to be greater than 0" do
      job = build(:crafting_job, batch_quantity: 0)
      expect(job).not_to be_valid
      expect(job.errors[:batch_quantity]).to be_present
    end
  end

  describe "enums" do
    it "defines status enum" do
      expect(described_class.statuses).to eq({
        "queued" => 0,
        "in_progress" => 1,
        "completed" => 2,
        "failed" => 3
      })
    end

    it "defines quality_tier enum" do
      expect(described_class.quality_tiers.keys).to contain_exactly(
        "common", "uncommon", "rare", "epic", "legendary"
      )
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:queued_job) { create(:crafting_job, user: user, character: character, recipe: recipe, crafting_station: crafting_station, status: :queued) }
      let!(:in_progress_job) { create(:crafting_job, user: user, character: character, recipe: recipe, crafting_station: crafting_station, status: :in_progress) }
      let!(:completed_job) { create(:crafting_job, user: user, character: character, recipe: recipe, crafting_station: crafting_station, status: :completed) }
      let!(:failed_job) { create(:crafting_job, user: user, character: character, recipe: recipe, crafting_station: crafting_station, status: :failed) }

      it "returns only queued and in_progress jobs" do
        expect(described_class.active).to contain_exactly(queued_job, in_progress_job)
      end
    end

    describe ".for_character" do
      let(:other_character) { create(:character) }
      let!(:job_for_character) { create(:crafting_job, user: user, character: character, recipe: recipe, crafting_station: crafting_station) }
      let!(:job_for_other) { create(:crafting_job, user: other_character.user, character: other_character, recipe: recipe, crafting_station: crafting_station) }

      it "returns only jobs for the specified character" do
        expect(described_class.for_character(character)).to contain_exactly(job_for_character)
      end
    end
  end

  describe "#progress_percent" do
    context "when job has not started" do
      it "returns 0" do
        job = build(:crafting_job, started_at: 1.hour.from_now, completes_at: 2.hours.from_now)
        expect(job.progress_percent).to eq(0)
      end
    end

    context "when job is completed" do
      it "returns 100" do
        job = build(:crafting_job, started_at: 2.hours.ago, completes_at: 1.hour.ago)
        expect(job.progress_percent).to eq(100)
      end
    end

    context "when job is in progress" do
      it "returns correct percentage" do
        # Job started 30 minutes ago, completes in 30 minutes (total 1 hour)
        job = build(:crafting_job, started_at: 30.minutes.ago, completes_at: 30.minutes.from_now)
        expect(job.progress_percent).to eq(50)
      end
    end

    context "when completes_at equals started_at" do
      it "returns 0 to avoid division by zero" do
        time = Time.current
        job = build(:crafting_job, started_at: time, completes_at: time)
        expect(job.progress_percent).to eq(0)
      end
    end
  end

  describe "#portable?" do
    it "returns true when portable_penalty_applied is true" do
      job = build(:crafting_job, portable_penalty_applied: true)
      expect(job.portable?).to be true
    end

    it "returns false when portable_penalty_applied is false" do
      job = build(:crafting_job, portable_penalty_applied: false)
      expect(job.portable?).to be false
    end
  end

  describe "delegation" do
    it "delegates profession to recipe" do
      expect(crafting_job.profession).to eq(profession)
    end
  end

  # Regression test for: ActionView::MissingTemplate - crafting_jobs/_crafting_job
  # Bug: broadcasts_to was using default partial naming (_crafting_job.html.erb)
  # but the actual partial is _job.html.erb
  describe "Turbo Streams broadcast configuration" do
    it "configures broadcasts_to with correct partial option" do
      # The model should specify partial: "crafting_jobs/job" in broadcasts_to
      # to avoid using the default _crafting_job.html.erb which doesn't exist
      model_source = File.read(Rails.root.join("app/models/crafting_job.rb"))

      expect(model_source).to include('partial: "crafting_jobs/job"')
    end

    it "has the correct partial file that exists" do
      # Verify the actual partial exists
      partial_path = Rails.root.join("app/views/crafting_jobs/_job.html.erb")
      expect(File.exist?(partial_path)).to be true
    end

    it "does NOT have the default partial that would cause MissingTemplate error" do
      # If this partial exists, Rails would use it by default and the bug wouldn't manifest
      # But if someone creates it, they might break the intentional partial: option
      wrong_partial_path = Rails.root.join("app/views/crafting_jobs/_crafting_job.html.erb")
      expect(File.exist?(wrong_partial_path)).to be false
    end
  end

  # Regression test for: NoMethodError - undefined method 'result_quality' for CraftingJob
  # Bug: The partial called job.result_quality but the column is quality_tier
  describe "partial rendering with quality_tier" do
    it "partial uses quality_tier column, not result_quality" do
      partial_content = File.read(Rails.root.join("app/views/crafting_jobs/_job.html.erb"))

      # Verify the partial does NOT use the incorrect column name
      expect(partial_content).not_to include("result_quality")

      # Verify it uses the correct column name
      expect(partial_content).to include("quality_tier")
    end

    it "CraftingJob responds to quality_tier but not result_quality" do
      job = build(:crafting_job)

      expect(job).to respond_to(:quality_tier)
      expect(job).not_to respond_to(:result_quality)
    end

    it "renders completed jobs without error" do
      completed_job = create(:crafting_job,
        user: user,
        character: character,
        recipe: recipe,
        crafting_station: crafting_station,
        status: :completed,
        quality_tier: :rare)

      # This should not raise NoMethodError for result_quality
      expect {
        ApplicationController.render(
          partial: "crafting_jobs/job",
          locals: {job: completed_job}
        )
      }.not_to raise_error
    end
  end
end
