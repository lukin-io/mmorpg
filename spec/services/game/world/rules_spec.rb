# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::Rules do
  let(:data) { YAML.safe_load_file(described_class::CONFIG_PATH, aliases: false) }

  it "loads the documented defaults including the captured drinking duration and recovery" do
    rules = described_class.load

    expect(rules.movement).to include("base_seconds" => 30, "minimum_seconds" => 24)
    expect(rules.fatigue).to include("outdoor_action_lock_percent" => 86, "recovery_interval_seconds" => 180)
    expect(rules.local_action_duration_seconds("resource_search")).to eq(28)
    expect(rules.local_action_duration_seconds("fishing")).to eq(30)
    expect(rules.local_action_duration_seconds("drinking")).to eq(60)
    expect(rules.drinking_fatigue_recovery_points).to eq(2)
    expect(rules.drinking_fatigue_recovery_points(nature_child: true)).to eq(4)
    expect(rules.presence_freshness_seconds).to eq(300)
  end

  it "copies and freezes supplied data so later editor changes cannot alter a ruleset" do
    rules = described_class.new(data:)
    data.fetch("movement")["base_seconds"] = 60
    data.dig("local_actions", "resource_search")["duration_seconds"] = 60

    expect(rules.movement.fetch("base_seconds")).to eq(30)
    expect(rules.local_action_duration_seconds("resource_search")).to eq(28)
    expect { rules.movement["base_seconds"] = 60 }.to raise_error(FrozenError)
    expect { rules.fatigue["recovery_points"] = 2 }.to raise_error(FrozenError)
  end

  it "uses only the injected RNG and configured fatigue gain bounds" do
    data.fetch("fatigue").merge!("movement_gain_min" => 3, "movement_gain_max" => 5)
    rules = described_class.new(data:)
    rng = instance_double(Random)
    expect(rng).to receive(:rand).with(3..5).and_return(4)

    expect(rules.movement_fatigue_gain(rng:)).to eq(4)
  end

  it "rejects missing, extra, non-string, and malformed section keys clearly" do
    [nil, [], data.except("movement"), data.merge("expression" => "eval"), data.merge(movement: {})].each do |invalid|
      expect { described_class.new(data: invalid) }
        .to raise_error(described_class::InvalidConfigurationError, /world must contain exactly/)
    end
    data["movement"] = nil
    expect { described_class.new(data:) }
      .to raise_error(described_class::InvalidConfigurationError, /movement must contain exactly/)
  end

  it "rejects invalid movement bounds and non-integer coefficients" do
    [
      ["base_seconds", 0], ["base_seconds", 3601], ["base_seconds", "30"],
      ["minimum_seconds", 31], ["wanderer_max_level", 0],
      ["wanderer_max_level", 101], ["wanderer_max_reduction_seconds", 7],
      ["wanderer_max_reduction_seconds", 1.5], ["wanderer_max_reduction_seconds", Float::INFINITY]
    ].each do |key, value|
      invalid = data.deep_dup
      invalid.fetch("movement")[key] = value
      expect { described_class.new(data: invalid) }
        .to raise_error(described_class::InvalidConfigurationError, /movement.#{key}/)
    end
  end

  it "rejects zero recovery intervals, reversed gain bounds, and invalid percentages" do
    [
      ["recovery_interval_seconds", 0], ["recovery_interval_seconds", 86_401],
      ["recovery_points", 0], ["outdoor_action_lock_percent", 101],
      ["movement_gain_min", -1], ["movement_gain_max", 0]
    ].each do |key, value|
      invalid = data.deep_dup
      invalid.fetch("fatigue")[key] = value
      expect { described_class.new(data: invalid) }
        .to raise_error(described_class::InvalidConfigurationError, /fatigue.#{key}/)
    end
  end

  it "allows only a positive bounded Look duration and rejects unrecognized action formulas" do
    [nil, false, "28", 0, 3601].each do |value|
      invalid = data.deep_dup
      invalid.dig("local_actions", "resource_search")["duration_seconds"] = value
      expect { described_class.new(data: invalid) }
        .to raise_error(described_class::InvalidConfigurationError, /resource_search.duration_seconds/)
    end
    data["local_actions"]["digging"] = {"duration_seconds" => 10}
    expect { described_class.new(data:) }
      .to raise_error(described_class::InvalidConfigurationError, /local_actions must contain exactly/)
  end

  it "validates configured drinking timing and recovery" do
    data.dig("local_actions", "drinking")["duration_seconds"] = 12
    expect(described_class.new(data:).local_action_duration_seconds("drinking")).to eq(12)

    ["duration_seconds", "fatigue_recovery_points", "nature_child_recovery_points"].each do |key|
      invalid = data.deep_dup
      invalid.dig("local_actions", "drinking")[key] = 0
      expect { described_class.new(data: invalid) }
        .to raise_error(described_class::InvalidConfigurationError, /drinking.#{key}/)
    end
  end

  it "rejects an invalid presence freshness window" do
    [0, -1, 86_401, "300", nil].each do |value|
      data.fetch("presence")["freshness_seconds"] = value
      expect { described_class.new(data:) }
        .to raise_error(described_class::InvalidConfigurationError, /presence.freshness_seconds/)
    end
  end

  it "reports malformed YAML and missing files as configuration errors" do
    Tempfile.create(["world-rules", ".yml"]) do |file|
      file.write("movement: [")
      file.flush
      expect { described_class.load(path: file.path) }
        .to raise_error(described_class::InvalidConfigurationError, /could not be loaded/)
    end
    expect { described_class.load(path: Rails.root.join("tmp/absent-world-rules.yml")) }
      .to raise_error(described_class::InvalidConfigurationError, /could not be loaded/)
  end

  it "retains the last valid default when a replacement cannot load" do
    original = described_class.default
    allow(described_class).to receive(:load).and_raise(described_class::InvalidConfigurationError, "invalid replacement")

    expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError)
    expect(described_class.default).to equal(original)
  end
end
