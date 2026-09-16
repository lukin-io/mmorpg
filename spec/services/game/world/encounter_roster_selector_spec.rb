# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::EncounterRosterSelector do
  let(:bandit) do
    create(
      :npc_template,
      npc_key: "wilderness_bandit_spec",
      name: "Bandit Spec",
      level: 7,
      metadata: {"health" => 155, "base_damage" => 5}
    )
  end
  let(:tile_npc) do
    create(
      :tile_npc,
      npc_template: bandit,
      npc_key: bandit.npc_key,
      level: 7,
      current_hp: 155,
      max_hp: 155
    )
  end

  it "preserves a fixed defeat reward separately and rejects malformed persisted values" do
    tile_npc.update!(metadata: {"encounter_experience_reward" => 631, "encounter_defeat_experience_reward" => 57})
    selection = described_class.new(tile_npc:).call
    expect(selection).to have_attributes(experience_reward: 631, defeat_experience_reward: 57)

    [nil, -1, 1.5, "57"].each do |value|
      tile_npc.update_columns(metadata: {"encounter_defeat_experience_reward" => value})
      expect { described_class.new(tile_npc:).call }.to raise_error(described_class::InvalidRosterError)
    end
  end

  it "keeps the fixed repeated-template fallback without consuming randomness" do
    tile_npc.update!(metadata: {"encounter_count" => 2, "encounter_experience_reward" => 35})
    rng = instance_double(Random)
    allow(rng).to receive(:rand)

    selection = described_class.new(tile_npc:, rng:).call

    expect(selection.members.map(&:npc_template)).to eq([bandit, bandit])
    expect(selection.members.map(&:max_hp)).to eq([155, 155])
    expect(selection.experience_reward).to eq(35)
    expect(selection.sample_key).to be_nil
    expect(rng).not_to have_received(:rand)
  end

  it "uses the template reward when a fixed encounter has no fight-level override" do
    bandit.update!(metadata: bandit.metadata.merge("xp_reward" => 35))
    tile_npc.update!(metadata: {"encounter_count" => 2})

    selection = described_class.new(tile_npc:).call

    expect(selection.experience_reward).to eq(35)
  end

  it "filters whole groups before weighted selection without truncating their rewards" do
    tile_npc.update!(metadata: {"encounter_rosters" => [
      {"key" => "too-large", "weight" => 99, "encounter_experience_reward" => 999,
       "members" => Array.new(3) { {"npc_key" => bandit.npc_key} }},
      {"key" => "pair", "weight" => 2, "encounter_experience_reward" => 35,
       "members" => Array.new(2) { {"npc_key" => bandit.npc_key} }},
      {"key" => "single", "weight" => 3, "encounter_experience_reward" => 9,
       "members" => [{"npc_key" => bandit.npc_key}]}
    ]})
    rng = instance_double(Random)
    allow(rng).to receive(:rand).with(5).and_return(1, 2)

    pair = described_class.new(tile_npc:, max_members: 2, rng:).call
    single = described_class.new(tile_npc:, max_members: 2, rng:).call

    expect(pair).to have_attributes(sample_key: "pair", experience_reward: 35)
    expect(pair.members.size).to eq(2)
    expect(single).to have_attributes(sample_key: "single", experience_reward: 9)
    expect(single.members.size).to eq(1)
  end

  it "does not invent a smaller fixed roster or alter its captured XP" do
    tile_npc.update!(metadata: {"encounter_count" => 2, "encounter_experience_reward" => 35})
    expect { described_class.new(tile_npc:, max_members: 1, rng: instance_double(Random)).call }
      .to raise_error(described_class::NoEligibleRosterError)
    expect(tile_npc.reload.metadata).to include("encounter_count" => 2, "encounter_experience_reward" => 35)
  end

  it "fails closed for an empty eligible sample set without drawing randomness" do
    tile_npc.update!(metadata: {"encounter_rosters" => [
      {"key" => "pair", "members" => Array.new(2) { {"npc_key" => bandit.npc_key} }}
    ]})
    expect { described_class.new(tile_npc:, max_members: 1, rng: instance_double(Random)).call }
      .to raise_error(described_class::NoEligibleRosterError)
  end

  it "preserves a fixed level-zero anchor without changing its HP or reward" do
    tile_npc.update!(level: 0, metadata: {"encounter_experience_reward" => 0})

    selection = described_class.new(tile_npc:, rng: instance_double(Random)).call

    expect(selection.members.first).to have_attributes(level: 0, max_hp: 155)
    expect(selection.experience_reward).to eq(0)
  end

  it "preserves an exact zero level over the template and samples a zero range boundary" do
    tile_npc.update!(metadata: {"encounter_rosters" => [
      {"key" => "zero", "members" => [
        {"npc_key" => bandit.npc_key, "level" => 0, "hp" => 40},
        {"npc_key" => bandit.npc_key, "level_min" => 0, "level_max" => 4, "hp" => 40}
      ]}
    ]})
    rng = instance_double(Random)
    allow(rng).to receive(:rand).with(0..4).and_return(0)

    selection = described_class.new(tile_npc:, rng:).call

    expect(selection.members.map(&:level)).to eq([0, 0])
    expect(selection.members.map(&:max_hp)).to eq([40, 40])
    expect(rng).to have_received(:rand).with(0..4).once
  end

  it "fails closed on persisted missing, negative, or fractional exact levels" do
    [nil, -1, 0.5].each do |level|
      tile_npc.update_columns(metadata: {"encounter_rosters" => [
        {"key" => "invalid", "members" => [{"npc_key" => bandit.npc_key, "level" => level, "hp" => 40}]}
      ]})

      expect { described_class.new(tile_npc:).call }
        .to raise_error(described_class::InvalidRosterError, /combat parameters/)
    end
  end

  it "preserves an explicit zero reward instead of falling back to the template" do
    bandit.update!(metadata: bandit.metadata.merge("xp_reward" => 35))
    tile_npc.update!(metadata: {"encounter_experience_reward" => 0})

    selection = described_class.new(tile_npc:).call

    expect(selection.experience_reward).to eq(0)
  end

  it "selects one complete captured sample and preserves member order and overrides" do
    robber = create(
      :npc_template,
      npc_key: "wilderness_robber_spec",
      name: "Robber Spec",
      level: 8,
      metadata: {"health" => 270, "base_damage" => 6}
    )
    tile_npc.update!(metadata: {
      "encounter_rosters" => [
        {
          "key" => "single",
          "encounter_experience_reward" => 9,
          "trauma_percent" => 30,
          "members" => [{"npc_key" => bandit.npc_key, "level" => 7, "hp" => 155}]
        },
        {
          "key" => "mixed",
          "encounter_experience_reward" => 56,
          "trauma_percent" => 80,
          "members" => [
            {"npc_key" => robber.npc_key, "level" => 9, "hp" => 310},
            {"npc_key" => bandit.npc_key, "level" => 8, "hp" => 185}
          ]
        }
      ]
    })
    rng = instance_double(Random, rand: 1)

    selection = described_class.new(tile_npc:, rng:).call

    expect(rng).to have_received(:rand).with(2)
    expect(selection.sample_key).to eq("mixed")
    expect(selection.experience_reward).to eq(56)
    expect(selection.trauma_percent).to eq(80)
    expect(selection.members.map { |member| member.npc_template.npc_key }).to eq(
      [robber.npc_key, bandit.npc_key]
    )
    expect(selection.members.map(&:level)).to eq([9, 8])
    expect(selection.members.map(&:max_hp)).to eq([310, 185])
  end

  it "fails closed when persisted roster data references a missing template" do
    tile_npc.update_columns(metadata: {
      "encounter_rosters" => [
        {"key" => "missing", "members" => [{"npc_key" => "deleted-template", "level" => 8, "hp" => 100}]}
      ]
    })

    expect {
      described_class.new(tile_npc:, rng: instance_double(Random)).call
    }.to raise_error(described_class::InvalidRosterError, /deleted-template.*unavailable/)
  end

  it "fails closed when persisted roster or member metadata has the wrong shape" do
    tile_npc.update_columns(metadata: {"encounter_rosters" => ["invalid"]})

    expect {
      described_class.new(tile_npc:).call
    }.to raise_error(described_class::InvalidRosterError, /roster is not documented/)

    tile_npc.update_columns(metadata: {
      "encounter_rosters" => [
        {
          "key" => "bad-member-metadata",
          "members" => [{"npc_key" => bandit.npc_key, "metadata" => "invalid"}]
        }
      ]
    })

    expect {
      described_class.new(tile_npc:).call
    }.to raise_error(described_class::InvalidRosterError, /member metadata is not documented/)
  end

  it "uses explicit relative weights and samples only within the authored level range" do
    tile_npc.update!(metadata: {"encounter_rosters" => [
      {"key" => "fixed", "weight" => 2, "members" => [{"npc_key" => bandit.npc_key}]},
      {"key" => "ranged", "weight" => 3, "members" => [{"npc_key" => bandit.npc_key, "level_min" => 11, "level_max" => 14, "hp" => 200}]}
    ]})
    rng = instance_double(Random)
    allow(rng).to receive(:rand).with(5).and_return(2)
    allow(rng).to receive(:rand).with(11..14).and_return(14)

    selection = described_class.new(tile_npc:, rng:).call

    expect(selection.sample_key).to eq("ranged")
    expect(selection.members.first).to have_attributes(level: 14, max_hp: 200)
    expect(selection.members.first.npc_template).to eq(bandit)
  end

  it "does not draw randomness for one fixed-width level range" do
    tile_npc.update!(metadata: {"encounter_rosters" => [
      {"key" => "same", "members" => [{"npc_key" => bandit.npc_key, "level_min" => 8, "level_max" => 8, "hp" => 200}]}
    ]})
    rng = instance_double(Random)

    expect(described_class.new(tile_npc:, rng:).call.members.first.level).to eq(8)
  end

  it "fails closed for malformed persisted weights and ranges" do
    [
      {"key" => "bad-weight", "weight" => 0, "members" => [{"npc_key" => bandit.npc_key}]},
      {"key" => "bad-range", "members" => [{"npc_key" => bandit.npc_key, "level_min" => 8, "level_max" => 7, "hp" => 200}]}
    ].each do |sample|
      tile_npc.update_columns(metadata: {"encounter_rosters" => [sample]})
      expect { described_class.new(tile_npc:).call }.to raise_error(described_class::InvalidRosterError)
    end
  end
end
