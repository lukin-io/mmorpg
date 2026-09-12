# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatProfile do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:arena_match) { create(:arena_match, status: :live) }
  let(:participation) { create(:arena_participation, arena_match:, character:, user:, team: "a") }

  it "replays the captured Neverlands fight payload from stored metadata" do
    participation.update!(
      metadata: {
        "combat_profile" => {
          "ap_limit" => 140,
          "physical_attack_cost_seed" => 67,
          "max_magic_mana" => 52,
          "block_table" => "normal"
        }
      }
    )

    profile = described_class.for_participation(participation)

    expect(profile).to include(
      "ap_limit" => 140,
      "physical_attack_cost_seed" => 67,
      "simple_attack_cost" => 67,
      "aimed_attack_cost" => 87,
      "max_magic_mana" => 52,
      "block_table" => "normal"
    )
  end

  it "uses explicit physical attack cost metadata without family fallbacks" do
    axe = create(:item_template,
      name: "Training Axe",
      slot: "main_hand",
      stat_modifiers: {"attack" => 10, "weapon_family" => "axe", "physical_attack_cost_bonus" => 13})
    armor = create(:item_template,
      :armor,
      name: "Training Armor",
      stat_modifiers: {"defense" => 10, "weapon_family" => "armor"})
    create(:inventory_item, inventory: character.inventory, item_template: axe, equipped: true)
    create(:inventory_item, inventory: character.inventory, item_template: armor, equipped: true)

    profile = described_class.for_participation(participation)

    expect(profile["physical_attack_cost_seed"]).to eq(58)
    expect(profile["simple_attack_cost"]).to eq(58)
    expect(profile["aimed_attack_cost"]).to eq(78)
  end

  it "does not infer physical attack cost from item family or attack stat" do
    axe = create(:item_template,
      name: "Training Axe",
      slot: "main_hand",
      stat_modifiers: {"attack" => 10, "weapon_family" => "axe"})
    create(:inventory_item, inventory: character.inventory, item_template: axe, equipped: true)

    profile = described_class.for_participation(participation)

    expect(profile["physical_attack_cost_seed"]).to eq(45)
    expect(profile["simple_attack_cost"]).to eq(45)
    expect(profile["aimed_attack_cost"]).to eq(65)
  end

  it "does not infer a shield selector tier from equipment family alone" do
    shield = create(:item_template,
      name: "Round Shield",
      slot: "off_hand",
      stat_modifiers: {"defense" => 8, "weapon_family" => "shield"})
    create(:inventory_item, inventory: character.inventory, item_template: shield, equipped: true)

    expect(described_class.for_participation(participation)["block_table"]).to eq("normal")
  end

  it "uses the exact shield selector table authored by the equipped item" do
    shield = create(:item_template,
      name: "Round Shield",
      slot: "off_hand",
      stat_modifiers: {"defense" => 8, "weapon_family" => "shield", "shield_block_table" => 90})
    create(:inventory_item, inventory: character.inventory, item_template: shield, equipped: true)

    expect(described_class.for_participation(participation)["block_table"]).to eq("shield_90")
  end

  it "derives each new fight from equipped gear without reusing the previous defensive stance" do
    character.update!(metadata: {"block_table" => "normal", "blocking" => false})
    shield = create(:item_template, slot: "off_hand", stat_modifiers: {"weapon_family" => "shield"})
    item = create(:inventory_item, inventory: character.inventory, item_template: shield,
      equipped: true, properties: {"block_table" => "shield_90"})

    expect(described_class.persist!(participation)["block_table"]).to eq("shield_90")

    character.update!(metadata: {"block_table" => "shield_90", "blocking" => false})
    item.update!(equipped: false)
    next_fight = create(:arena_participation, character:, user:, team: "a")

    expect(described_class.for_participation(next_fight)["block_table"]).to eq("normal")
    expect(described_class.for_participation(participation.reload)["block_table"]).to eq("shield_90")
  end

  it "normalizes the numeric shield selector sent by fight_pm" do
    participation.update!(metadata: {"combat_profile" => {"block_table" => 70}})

    expect(described_class.for_participation(participation)["block_table"]).to eq("shield_70")
  end

  it "retains only explicitly injected magic blocks from profile metadata" do
    participation.update!(
      metadata: {
        "combat_profile" => {
          "injected_attack_keys" => %w[spirit_arrow simple invented_attack],
          "injected_block_keys" => %w[magic_shield torso_block invented_block]
        }
      }
    )

    profile = described_class.for_participation(participation)

    expect(profile["injected_attack_keys"]).to eq(["spirit_arrow"])
    expect(profile["injected_block_keys"]).to eq(["magic_shield"])
  end

  it "lets NPCs inherit captured fight AP without level-derived physical attack cost" do
    arena_match.update!(
      metadata: {
        "combat_profile" => {
          "ap_limit" => 140,
          "physical_attack_cost_seed" => 67,
          "simple_attack_cost" => 67,
          "aimed_attack_cost" => 87,
          "max_magic_mana" => 52,
          "block_table" => "shield_90",
          "injected_attack_keys" => ["spirit_arrow"],
          "injected_block_keys" => ["magic_shield"]
        }
      }
    )
    npc = create(:npc_template, role: "arena_bot", level: 5)
    npc_participation = create(:arena_participation, :npc, arena_match:, npc_template: npc, team: "b")

    profile = described_class.for_participation(npc_participation)

    expect(profile["ap_limit"]).to eq(140)
    expect(profile["physical_attack_cost_seed"]).to eq(45)
    expect(profile["simple_attack_cost"]).to eq(45)
    expect(profile["aimed_attack_cost"]).to eq(65)
    expect(profile["max_magic_mana"]).to eq(52)
    expect(profile["block_table"]).to eq("normal")
    expect(profile["injected_attack_keys"]).to eq([])
    expect(profile["injected_block_keys"]).to eq([])
  end

  describe "equipped instance inputs" do
    %w[physical_attack_cost_seed attack_cost_seed].each do |key|
      it "uses merged instance #{key} ahead of template and root properties" do
        template = create(:item_template, stat_modifiers: {key => 72})
        item = create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
          properties: {key => 80, "stat_modifiers" => {key => 66}})

        expect(described_class.physical_attack_seed(participation)).to eq(66)

        item.update!(properties: item.properties.merge("effects" => {key => 58}))

        expect(described_class.physical_attack_seed(participation)).to eq(58)
        expect(described_class.attack_cost(participation, "aimed")).to eq(78)
      end
    end

    %w[block_table shield_block_table].each do |key|
      it "uses merged instance #{key} and lets an explicit normal table remove the template shield" do
        template = create(:item_template, slot: "off_hand", stat_modifiers: {key => 90})
        item = create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
          properties: {key => 40, "stat_modifiers" => {key => 70}})

        expect(described_class.for_participation(participation)["block_table"]).to eq("shield_70")

        item.update!(properties: item.properties.merge("effects" => {key => "normal"}))

        expect(described_class.for_participation(participation)["block_table"]).to eq("normal")
      end
    end

    %w[physical_attack_cost_bonus attack_cost_bonus].each do |key|
      it "preserves signed #{key} from merged instance effects" do
        template = create(:item_template, stat_modifiers: {key => 13})
        item = create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
          properties: {key => 20, "stat_modifiers" => {key => -10}})

        expect(described_class.physical_attack_seed(participation)).to eq(35)

        item.update!(properties: item.properties.merge("effects" => {key => 0}))

        expect(described_class.physical_attack_seed(participation)).to eq(45)
      end
    end

    it "sums positive and negative adjustments before flooring the resulting cost" do
      weapon = create(:item_template, stat_modifiers: {"attack_cost_bonus" => -50})
      armor = create(:item_template, :armor, stat_modifiers: {"physical_attack_cost_bonus" => 10})
      create(:inventory_item, inventory: character.inventory, item_template: weapon, equipped: true)
      armor_item = create(:inventory_item, inventory: character.inventory, item_template: armor, equipped: true)

      expect(described_class.physical_attack_seed(participation)).to eq(5)

      armor_item.update!(equipped: false)

      expect(described_class.physical_attack_seed(participation)).to eq(1)
      expect(described_class.attack_cost(participation, "aimed")).to eq(21)
    end

    {nil => 45, "invalid" => 45, -44 => 1, -43 => 2}.each do |bonus, expected|
      it "handles the #{bonus.inspect} attack adjustment boundary without a positive seed clamp" do
        template = create(:item_template, stat_modifiers: {"attack_cost_bonus" => 13})
        create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
          properties: {"effects" => {"attack_cost_bonus" => bonus}})

        expect(described_class.physical_attack_seed(participation)).to eq(expected)
      end
    end

    {nil => 45, "invalid" => 45, -1 => 1, 0 => 1, 1 => 1, 250 => 250, 251 => 250}.each do |seed, expected|
      it "retains the absolute item seed boundary for #{seed.inspect}" do
        template = create(:item_template, stat_modifiers: {"physical_attack_cost_seed" => 72})
        create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
          properties: {"physical_attack_cost_seed" => 80, "effects" => {"physical_attack_cost_seed" => seed}})

        expect(described_class.physical_attack_seed(participation)).to eq(expected)
      end
    end

    it "keeps root item properties supported when merged effects omit the fields" do
      template = create(:item_template, stat_modifiers: {"attack" => 1})
      item = create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
        properties: {"attack_cost_bonus" => -10, "shield_block_table" => 40})

      expect(described_class.for_participation(participation)).to include(
        "physical_attack_cost_seed" => 35, "block_table" => "shield_40"
      )

      item.update!(properties: item.properties.merge("attack_cost_seed" => 62))

      expect(described_class.physical_attack_seed(participation)).to eq(62)
    end

    it "ignores unequipped overrides and retains the greatest equipped explicit seed" do
      template = create(:item_template, stat_modifiers: {"attack_cost_seed" => 72})
      create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
        properties: {"effects" => {"attack_cost_seed" => 58}})
      create(:inventory_item, inventory: character.inventory, item_template: template, equipped: true,
        properties: {"effects" => {"attack_cost_seed" => 62}})
      create(:inventory_item, inventory: character.inventory, item_template: template, equipped: false,
        properties: {"effects" => {"attack_cost_seed" => 90, "block_table" => 90}})

      expect(described_class.for_participation(participation)).to include(
        "physical_attack_cost_seed" => 62, "block_table" => "normal"
      )
    end
  end

  describe "explicit profile precedence" do
    let(:injected_actions) do
      {"injected_attack_keys" => ["spirit_arrow"], "injected_block_keys" => ["magic_shield"]}
    end
    let(:empty_actions) { {"injected_attack_keys" => [], "injected_block_keys" => []} }
    let(:captured_profile) do
      injected_actions.merge("ap_limit" => 140, "physical_attack_cost_seed" => 67,
        "max_magic_mana" => 52, "block_table" => "shield_70")
    end

    it "retains character root inputs except the transient block stance" do
      character.update!(metadata: captured_profile)

      expect(described_class.for_participation(participation)).to include(captured_profile.merge("block_table" => "normal"))
    end

    it "lets an explicit character profile override root fields including the shield selector" do
      character.update!(metadata: {"ap_limit" => 80, "block_table" => "normal", "combat_profile" => captured_profile})

      expect(described_class.for_participation(participation)).to include(captured_profile)
    end

    it "retains match profile precedence for characters across numeric and action fields" do
      character.update!(metadata: {"combat_profile" => captured_profile.merge(empty_actions)})
      arena_match.update!(metadata: {"combat_profile" => captured_profile.merge("ap_limit" => 200, "block_table" => "shield_90")})

      expect(described_class.for_participation(participation)).to include(
        captured_profile.merge("ap_limit" => 200, "block_table" => "shield_90")
      )
    end

    it "lets participation root inputs override the match profile" do
      arena_match.update!(metadata: {"combat_profile" => captured_profile})
      participation.update!(metadata: captured_profile.merge(empty_actions).merge("ap_limit" => 100, "block_table" => "normal"))

      expect(described_class.for_participation(participation)).to include(
        captured_profile.merge(empty_actions).merge("ap_limit" => 100, "block_table" => "normal")
      )
    end

    it "keeps persisted empty action lists and zero mana ahead of every inherited input after reload" do
      character.update!(metadata: {"combat_profile" => captured_profile})
      arena_match.update!(metadata: {"combat_profile" => captured_profile})
      participation.update!(metadata: captured_profile.merge(
        "combat_profile" => empty_actions.merge("max_magic_mana" => 0)
      ))

      profile = described_class.persist!(participation)

      expect(profile).to include(empty_actions.merge("max_magic_mana" => 0))
      expect(described_class.for_participation(participation.reload)).to eq(profile)
    end

    it "lets empty match action lists disable character profile actions" do
      character.update!(metadata: {"combat_profile" => captured_profile})
      arena_match.update!(metadata: {"combat_profile" => empty_actions})

      expect(described_class.for_participation(participation)).to include(empty_actions)
    end

    it "lets empty character profile action lists disable root actions" do
      character.update!(metadata: injected_actions.merge("combat_profile" => empty_actions))

      expect(described_class.for_participation(participation)).to include(empty_actions)
    end

    it "does not resurrect lower priority numeric inputs when an explicit value is nil or malformed" do
      arena_match.update!(metadata: {"combat_profile" => captured_profile})
      participation.update!(metadata: {"combat_profile" => {"physical_attack_cost_seed" => nil, "max_magic_mana" => "invalid"}})

      expect(described_class.for_participation(participation)).to include(
        "physical_attack_cost_seed" => 45, "max_magic_mana" => character.max_mp
      )
    end

    it "uses NPC level profile inputs ahead of the shared match and honors empty injected lists" do
      arena_match.update!(metadata: {"combat_profile" => captured_profile})
      npc_profile = captured_profile.merge(empty_actions).merge("physical_attack_cost_seed" => 58, "max_magic_mana" => 0)
      npc = create(:npc_template, role: "arena_bot", level: 5,
        metadata: {"combat_profile" => captured_profile, "level_profiles" => {"5" => {"combat_profile" => npc_profile}}})
      npc_participation = create(:arena_participation, :npc, arena_match:, npc_template: npc, team: "b")

      expect(described_class.for_participation(npc_participation)).to include(npc_profile)
    end

    it "retains an NPC's own injected actions without borrowing the match's shield or attack seed" do
      arena_match.update!(metadata: {"combat_profile" => captured_profile})
      npc = create(:npc_template, role: "arena_bot", metadata: {"combat_profile" => injected_actions})
      npc_participation = create(:arena_participation, :npc, arena_match:, npc_template: npc, team: "b")

      expect(described_class.for_participation(npc_participation)).to include(
        injected_actions.merge("ap_limit" => 140, "physical_attack_cost_seed" => 45, "block_table" => "normal")
      )
    end

    it "lets explicit participation fields override an NPC content snapshot" do
      npc = create(:npc_template, role: "arena_bot", metadata: {"combat_profile" => captured_profile})
      npc_participation = create(:arena_participation, :npc, arena_match:, npc_template: npc, team: "b",
        metadata: {"npc_combat_data" => {"combat_profile" => captured_profile}, "combat_profile" => empty_actions,
                   "physical_attack_cost_seed" => 62, "block_table" => "normal"})

      expect(described_class.for_participation(npc_participation)).to include(
        empty_actions.merge("physical_attack_cost_seed" => 62, "block_table" => "normal", "ap_limit" => 140)
      )
    end
  end
end
