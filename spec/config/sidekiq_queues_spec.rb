# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sidekiq Queue Configuration" do
  let(:sidekiq_config) { YAML.load_file(Rails.root.join("config/sidekiq.yml")) }
  let(:configured_queues) { sidekiq_config[:queues] }

  describe "sidekiq.yml" do
    it "includes the arena queue for match processing" do
      expect(configured_queues).to include("arena")
    end

    it "includes the default queue" do
      expect(configured_queues).to include("default")
    end

    it "includes the movement queue" do
      expect(configured_queues).to include("movement")
    end

    it "includes the vitals queue for HP/MP regeneration" do
      expect(configured_queues).to include("vitals")
    end

    it "includes the chat queue" do
      expect(configured_queues).to include("chat")
    end

    it "includes the low priority queue" do
      expect(configured_queues).to include("low")
    end
  end

  describe "Arena jobs queue assignments" do
    it "MatchStarterJob uses arena queue" do
      expect(Arena::MatchStarterJob.new.queue_name).to eq("arena")
    end

    it "ArenaTurnTimeoutJob uses arena queue" do
      expect(ArenaTurnTimeoutJob.new.queue_name).to eq("arena")
    end

    it "ArenaTurnTimeoutWarningJob uses arena queue" do
      expect(ArenaTurnTimeoutWarningJob.new.queue_name).to eq("arena")
    end
  end

  describe "Queue coverage for all arena-related jobs" do
    let(:arena_job_classes) do
      [
        Arena::MatchStarterJob,
        ArenaTurnTimeoutJob,
        ArenaTurnTimeoutWarningJob
      ]
    end

    it "all arena jobs are assigned to a configured queue" do
      arena_job_classes.each do |job_class|
        queue_name = job_class.new.queue_name
        expect(configured_queues).to include(queue_name),
          "#{job_class} uses queue '#{queue_name}' which is not in sidekiq.yml"
      end
    end
  end

  describe "Critical job queue verification" do
    let(:critical_jobs) do
      {
        "Arena::MatchStarterJob" => "arena",
        "ArenaTurnTimeoutJob" => "arena",
        "ArenaTurnTimeoutWarningJob" => "arena"
      }
    end

    it "all critical jobs use their designated queues" do
      critical_jobs.each do |job_class_name, expected_queue|
        job_class = job_class_name.constantize
        actual_queue = job_class.new.queue_name

        expect(actual_queue).to eq(expected_queue),
          "#{job_class_name} expected queue '#{expected_queue}' but got '#{actual_queue}'"
      end
    end

    it "all designated queues are configured in sidekiq.yml" do
      critical_jobs.values.uniq.each do |queue_name|
        expect(configured_queues).to include(queue_name),
          "Queue '#{queue_name}' is used by a critical job but not in sidekiq.yml"
      end
    end
  end
end
