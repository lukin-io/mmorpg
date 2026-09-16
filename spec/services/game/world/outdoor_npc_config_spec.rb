# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::OutdoorNpcConfig do
  before do
    described_class.reload!
  end

  describe ".source_npc_for_tile" do
    it "loads the exact two-cell low-level samples and per-level equipment/stat profiles" do
      orc = described_class.source_npc_for_tile("Outpost Surroundings", 4, 12)
      skeleton = described_class.source_npc_for_tile("Outpost Surroundings", 4, 11)
      mixed = orc.dig(:metadata, :encounter_rosters).last
      expect(mixed[:members].pluck(:npc_key, :level, :hp)).to eq([
        ["wilderness_orc", 3, 65], ["wilderness_orc", 3, 65], ["wilderness_goblin", 3, 55]
      ])
      expect(mixed[:encounter_experience_reward]).to eq(1)
      expect(orc.dig(:metadata, :equipment).keys).to contain_exactly(:main_hand, :feet, :bracers, :belt)
      expect(orc.dig(:metadata, :level_profiles, :"4", :display_stats, :strength)).to eq(20)
      expect(skeleton.dig(:metadata, :equipment)).to eq({})
      expect(skeleton.dig(:metadata, :level_profiles).keys).to contain_exactly(:"7", :"8", :"9")
      expect(skeleton.dig(:metadata, :response_attack_counts)).to eq([2])
      expect(skeleton.dig(:metadata, :search_enabled)).to be false
      expect(described_class.find_npc("wilderness_goblin").dig(:metadata, :equipment, :chest, :artwork)).to eq("goblin_chainmail")
    end

    it "loads independently captured Bandit and Robber level setups without filling empty slots" do
      bandit = described_class.find_npc("wilderness_bandit").fetch(:metadata)
      robber = described_class.find_npc("wilderness_robber").fetch(:metadata)
      expect(bandit[:avatar_image]).to eq("bandit.png")
      expect(robber[:avatar_image]).to eq("robber.png")
      expect(bandit).not_to have_key(:equipment)
      expect(robber).not_to have_key(:equipment)
      expect(bandit[:level_profiles].keys).to contain_exactly(:"13", :"14", :"15")
      expect(robber[:level_profiles].keys).to contain_exactly(:"13", :"14", :"15")
      expect(bandit[:level_profiles].values.map { |profile| profile.dig(:display_stats, :armor_class) }).to eq([290, 340, 375])
      expect(robber[:level_profiles].values.map { |profile| profile.dig(:display_stats, :armor_class) }).to eq([388, 424, 485])
      [bandit, robber].each do |metadata|
        metadata[:level_profiles].each_value do |profile|
          expect(profile[:equipment].keys).not_to include(:legs, :ring_3, :ring_4, :relic)
          expect(profile[:equipment].values.map { |item| item[:artwork] } - NpcTemplate::EQUIPMENT_ARTWORK_KEYS).to be_empty
        end
      end
      expect(bandit[:level_profiles].values).to all(include(equipment: include(:off_hand)))
      robber[:level_profiles].each_value { |profile| expect(profile[:equipment]).not_to have_key(:off_hand) }
    end

    it "returns the captured plague rat at its mapped local coordinate" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 7, 7)

      expect(npc[:key]).to eq("plague_rat")
      expect(npc[:name]).to eq("Plague Rat")
      expect(npc[:hp]).to eq(100)
      expect(npc[:damage]).to eq(7)
      expect(npc.dig(:metadata, :source_map)).to eq("m_1001_999")
      expect(npc.dig(:metadata, :source_coordinates)).to eq([1001, 999])
      expect(npc.dig(:metadata, :encounter_count)).to eq(2)
      expect(npc.dig(:metadata, :encounter_experience_reward)).to eq(35)
      expect(npc.dig(:metadata, :combat_profile, :injected_attack_keys)).to eq(
        %w[spirit_arrow mind_blast]
      )
      expect(npc.dig(:metadata, :combat_profile, :injected_block_keys)).to eq(
        %w[magic_shield rainbow_barrier crystal_sphere]
      )
    end

    it "uses the authorized calibrated Plague Rat probability" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 7, 7)
      loot_entry = npc.fetch(:loot).first

      expect(loot_entry[:chance]).to eq(0.03)
      expect(Game::LootEntry.new(loot_entry).chance_percent).to eq(3.0)
    end

    it "does not invent NPCs for other coordinates in the same zone" do
      expect(described_class.source_npc_for_tile("Outpost Surroundings", 9, 7)).to be_nil
    end

    it "preserves the four captured m_1008_1007 roster samples and timing windows" do
      npc = described_class.source_npc_for_tile("Outpost Surroundings", 14, 15)
      rosters = npc.dig(:metadata, :encounter_rosters)

      expect(npc[:key]).to eq("wilderness_bandit")
      expect(npc.dig(:metadata, :source_map)).to eq("m_1008_1007")
      expect(npc.dig(:metadata, :source_capture_scope)).to eq("independent_encounter_sample")
      expect(npc.dig(:metadata, :source_coordinates)).to eq([1008, 1007])
      expect(npc.dig(:metadata, :source_coordinate_offset)).to eq([994, 992])
      expect(described_class.source_npc_for_tile("Outpost Surroundings", 8, 7)).to be_nil
      expect(npc.dig(:metadata, :passive_delay_windows)).to eq(
        [
          {key: "2026-09-01-interval-1", min_seconds: 230, max_seconds: 278},
          {key: "2026-09-01-interval-2", min_seconds: 127, max_seconds: 187}
        ]
      )
      expect(rosters.map { |sample| sample[:key] }).to eq(
        %w[2026-09-01-2334 2026-09-01-2340 2026-09-01-2345 2026-09-01-2351]
      )
      expect(rosters.map { |sample| sample[:members].size }).to eq([3, 1, 1, 2])
      expect(rosters.last[:members].pluck(:npc_key, :level, :hp)).to eq(
        [["wilderness_bandit", 8, 185], ["wilderness_robber", 9, 310]]
      )
      expect(described_class.find_npc("wilderness_robber")[:name]).to eq("Robber")
    end
  end

  describe ".find_encounter_preset" do
    captures = [
      ["2050", 0, [["wilderness_bandit", 13, 605], ["wilderness_bandit", 14, 835], ["wilderness_bandit", 14, 835]]],
      ["2103", 631, [["wilderness_bandit", 14, 835]]],
      ["2108", 13_183, [["wilderness_bandit", 13, 605], ["wilderness_bandit", 13, 605],
        ["wilderness_robber", 13, 695], ["wilderness_robber", 14, 815], ["wilderness_robber", 15, 1005], ["wilderness_robber", 15, 1005]]],
      ["2120", 764, [["wilderness_bandit", 15, 945]]],
      ["2126", 494, [["wilderness_robber", 14, 815]]],
      ["2131", 778, [["wilderness_bandit", 14, 835]]],
      ["2139", 820, [["wilderness_bandit", 14, 835], ["wilderness_bandit", 14, 835]]],
      ["2144", 381, [["wilderness_bandit", 13, 605]]],
      ["2150", 631, [["wilderness_bandit", 14, 835]]],
      ["2203", 493, [["wilderness_robber", 14, 815]]]
    ]

    captures.each_with_index do |(time, xp, members), index|
      it "preserves stage-2 fight #{index + 1} as one whole captured roster/result" do
        key = "2026-09-11-#{time}"
        preset = described_class.find_encounter_preset(key)
        metadata = preset.fetch(:metadata)
        sample = metadata.fetch(:encounter_rosters).sole

        expect(preset.keys).to contain_exactly(:key, :metadata)
        expect(preset[:key]).to eq(key)
        expect(metadata).to include(
          source_observation: "2026-09-11_stronger_npc_loot_combat_cycle",
          source_fight_number: index + 1, source_player_level: 17,
          encounter_selection_mode: "observed_sample_replay"
        )
        expect(sample[:key]).to eq(key)
        expect(sample[:members].pluck(:npc_key, :level, :hp)).to eq(members)
        expect(sample[:encounter_experience_reward]).to eq(xp)
        if index.zero?
          expect(sample[:encounter_defeat_experience_reward]).to eq(57)
        else
          expect(sample).not_to have_key(:encounter_defeat_experience_reward)
        end
        expect(metadata.keys & %i[x y source_coordinates trauma_percent loot_table passive_delay_windows]).to be_empty
        expect(sample.keys & %i[trauma_percent loot_table weight]).to be_empty
        expect(TileNpc.encounter_policy_errors(metadata.deep_stringify_keys)).to be_empty
      end
    end

    it "returns deeply independent copies and nil for an unknown key" do
      preset = described_class.find_encounter_preset("2026-09-11-2050")
      preset[:metadata][:source_observation].replace("changed")
      preset[:metadata][:encounter_rosters].first[:members].first[:hp] = 1
      preset[:metadata][:encounter_rosters].first[:encounter_defeat_experience_reward] = 1

      fresh = described_class.find_encounter_preset(:"2026-09-11-2050")
      expect(fresh[:metadata][:source_observation]).to eq("2026-09-11_stronger_npc_loot_combat_cycle")
      expect(fresh.dig(:metadata, :encounter_rosters, 0, :members, 0, :hp)).to eq(605)
      expect(fresh.dig(:metadata, :encounter_rosters, 0, :encounter_defeat_experience_reward)).to eq(57)
      expect(described_class.find_encounter_preset("unknown")).to be_nil
      expect(described_class.find_encounter_preset(nil)).to be_nil
    end

    it "catalogues ten presets under the observed region without creating NPC templates or placements" do
      expect(described_class.config.fetch(:oktal_surroundings).fetch(:encounter_presets).size).to eq(10)
      expect(described_class.for_zone("Oktal Surroundings")).to eq([])
      expect(described_class.has_npcs?("Oktal Surroundings")).to be(false)
      expect(described_class.source_npc_for_tile("Oktal Surroundings", 0, 0)).to be_nil
      expect(described_class.find_npc("2026-09-11-2050")).to be_nil
      expect(described_class.all_templates.pluck(:key)).not_to include("2026-09-11-2050")
    end

    it "rejects missing presets referenced by the calibrated starter habitats" do
      raw = YAML.load_file(described_class::CONFIG_PATH).except("oktal_surroundings")
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(raw)

      expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /calibrated habitat/)
    ensure
      described_class.instance_variable_set(:@config, nil)
    end

    context "with authored presets" do
      let(:sample) { {key: "capture", encounter_experience_reward: 0, encounter_defeat_experience_reward: 57, members: [{npc_key: "bandit", level: 13, hp: 605}]} }
      let(:preset) { {key: "preset", metadata: {encounter_rosters: [sample]}} }
      let(:raw) { {source: {npc_templates: [{key: "bandit", level: 13}]}, region: {encounter_presets: [preset]}} }

      before do
        allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(raw)
      end

      after { described_class.instance_variable_set(:@config, nil) }

      it "resolves template references across the config without requiring seeded database templates" do
        expect(NpcTemplate).not_to receive(:where)
        expect(described_class.reload!.dig(:region, :encounter_presets).sole).to eq(preset)
      end

      %i[encounter_experience_reward encounter_defeat_experience_reward].each do |field|
        [-1, "57", 1.5, nil].each do |invalid|
          it "rejects #{field}=#{invalid.inspect} before exposing the catalog" do
            sample[field] = invalid
            expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /#{field} must be a non-negative integer/)
          end
        end
      end

      it "rejects negative levels through the shared TileNpc policy" do
        sample[:members].first[:level] = -1
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /level must be a non-negative integer/)
      end

      [0, -1, nil, "605"].each do |hp|
        it "rejects incomplete or invalid captured HP #{hp.inspect}" do
          sample[:members].first[:hp] = hp
          expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /positive HP/)
        end
      end

      it "rejects an unknown template through the existing roster-reference validator" do
        sample[:members].first[:npc_key] = "missing"
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /references unknown template "missing"/)
      end

      it "rejects duplicate preset keys even across zones" do
        raw[:other_region] = {encounter_presets: [preset.deep_dup]}
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /duplicate encounter preset key preset/)
      end

      it "rejects missing and duplicate sample identities" do
        preset[:metadata][:encounter_rosters] << sample.deep_dup
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /roster keys must be present and unique/)
        preset[:metadata][:encounter_rosters] = [sample.except(:key)]
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /roster keys must be present and unique/)
      end

      it "reuses the shared sample-weight policy instead of silently accepting invalid weights" do
        sample[:weight] = 0
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /roster weight must/)
      end

      it "rejects missing preset identity or metadata" do
        preset[:key] = ""
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /preset key/)
        preset[:key] = "preset"
        preset[:metadata] = nil
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /requires encounter_rosters metadata/)
      end

      it "rejects malformed preset lists and empty roster captures" do
        raw[:region][:encounter_presets] = {}
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /presets must be an array/)
        raw[:region][:encounter_presets] = [preset]
        preset[:metadata][:encounter_rosters] = []
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /rosters must be a non-empty array/)
      end
    end
  end

  describe ".config" do
    it "validates reusable template rosters even when they have no standalone placement" do
      raw = {region: {npc_templates: [{key: "ogre", metadata: {encounter_rosters: [
        {key: "group", members: [{npc_key: "missing", level: 16, hp: 1455}]}
      ]}}]}}
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(raw)
      expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /references unknown template/)
    ensure
      described_class.instance_variable_set(:@config, nil)
    end

    it "rejects malformed authored NPC profiles before seeding" do
      metadata = {response_attack_counts: [5], equipment: {off_hand: {name: "Unknown", artwork: "../secret"}}}
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return({zone: {npcs: [{key: "invalid", metadata:}]}})
      expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /response_attack_counts/)
      metadata[:response_attack_counts] = [1, 2]
      expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /artwork is unavailable/)
    ensure
      described_class.instance_variable_set(:@config, nil)
    end

    it "accepts zero template/member levels and rejects negative or malformed levels on reload" do
      member = {npc_key: "zero_rat", level: 0, hp: 40}
      template = {key: "zero_rat", level: 0, metadata: {encounter_rosters: [{key: "zero", members: [member]}]}}
      config = {outpost: {zone_name: "Outpost", npcs: [template]}}
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(config)

      expect(described_class.reload!.dig(:outpost, :npcs, 0, :level)).to eq(0)
      [nil, -1, 0.5].each do |invalid|
        template[:level] = invalid
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /level must be a non-negative integer/)
        template[:level] = 0
        member[:level] = invalid
        expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /level must be a non-negative integer/)
      end
    ensure
      described_class.instance_variable_set(:@config, nil)
    end

    it "validates authored weights, level ranges and activation at the catalog boundary" do
      member = {npc_key: "range_spec", level_min: 0, level_max: 4, hp: 200}
      sample = {key: "range", weight: 3, members: [member]}
      config = {outpost: {zone_name: "Outpost", npcs: [{key: "range_spec", metadata: {active: false, encounter_rosters: [sample]}}]}}
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(config)

      expect(described_class.reload!.dig(:outpost, :npcs, 0, :metadata, :active)).to be false
      sample[:weight] = 0
      expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /weight must/)
      sample[:weight] = 1
      member.delete(:hp)
      expect { described_class.reload! }.to raise_error(described_class::InvalidConfigurationError, /requires explicit hp/)
    ensure
      described_class.instance_variable_set(:@config, nil)
    end

    it "loads a ten-member authored roster and rejects an eleventh member on reload" do
      members = Array.new(10) { {npc_key: "capacity_spec"} }
      boundary_config = {
        outpost: {
          zone_name: "Outpost",
          npcs: [{key: "capacity_spec", metadata: {encounter_rosters: [{key: "boundary", members:}]}}]
        }
      }
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(boundary_config)

      loaded = described_class.reload!
      expect(loaded.dig(:outpost, :npcs, 0, :metadata, :encounter_rosters, 0, :members).size).to eq(10)

      members << {npc_key: "capacity_spec"}
      expect { described_class.reload! }.to raise_error(
        described_class::InvalidConfigurationError, /roster 0 has invalid members/
      )
    ensure
      described_class.instance_variable_set(:@config, nil)
    end

    it "rejects a developer-authored loot entry without an explicit chance" do
      invalid_config = {
        outpost: {
          zone_name: "Outpost",
          npcs: [{key: "invalid", loot: [{kind: "item", item: "rat_tail"}]}]
        }
      }
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(invalid_config)
      described_class.instance_variable_set(:@config, nil)

      expect { described_class.config }.to raise_error(
        described_class::InvalidConfigurationError,
        /NPC invalid loot entry 0: Loot chance is required/
      )
    ensure
      described_class.instance_variable_set(:@config, nil)
    end


    it "rejects a captured roster that references an unknown template" do
      invalid_config = {
        outpost: {
          zone_name: "Outpost",
          npcs: [
            {
              key: "bandit",
              metadata: {
                encounter_rosters: [
                  {key: "bad", members: [{npc_key: "missing", level: 7, hp: 155}]}
                ]
              }
            }
          ]
        }
      }
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(invalid_config)
      described_class.instance_variable_set(:@config, nil)

      expect { described_class.config }.to raise_error(
        described_class::InvalidConfigurationError,
        /references unknown template "missing"/
      )
    ensure
      described_class.instance_variable_set(:@config, nil)
    end
  end
end
