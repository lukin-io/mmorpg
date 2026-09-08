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
    tile_npc.update!(metadata: {
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
end
