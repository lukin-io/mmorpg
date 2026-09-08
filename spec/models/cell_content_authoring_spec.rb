# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cell content authoring" do
  describe "resource groups" do
    let(:group) { {"key" => "herbs_7", "kind" => "herbs", "label" => "Herbs group 7", "active" => true} }

    it "keeps identities separate from yields and excludes deactivated groups" do
      cell = build(:map_tile_template, metadata: {"resource_groups" => [group, group.merge("key" => "herbs_11", "active" => false)]})

      expect(cell).to be_valid
      expect(cell.resource_groups.size).to eq(2)
      expect(cell.active_resource_groups).to eq([group])
      expect(cell.active_local_actions).to be_empty
    end

    it "rejects duplicate identities, malformed entries and non-boolean activation" do
      [nil, {"key" => "UPPER"}, {"label" => ""}, {"active" => "false"}].each do |changes|
        entry = changes ? group.merge(changes) : "invalid"
        expect(build(:map_tile_template, metadata: {"resource_groups" => [entry]})).not_to be_valid
      end
      expect(build(:map_tile_template, metadata: {"resource_groups" => [group, group]})).not_to be_valid
      expect(build(:map_tile_template, metadata: {"resource_groups" => Array.new(33) { group }})).not_to be_valid
    end
  end

  describe "NPC activation and roster policies" do
    it "deactivates without consuming or resetting the encounter's saved state" do
      npc = create(:tile_npc)
      before = npc.attributes.slice("current_hp", "defeated_at", "respawns_at")
      npc.update!(active: false)

      expect(npc.reload).not_to be_alive
      expect(TileNpc.active).not_to include(npc)
      expect(TileNpc.alive).not_to include(npc)
      expect(npc.attributes.slice(*before.keys)).to eq(before)
      npc.update!(active: true)
      expect(npc.reload).to be_alive
    end

    it "accepts bounded ranges only with explicit HP and integer weights" do
      create(:npc_template, npc_key: "rat")
      member = {"npc_key" => "rat", "level_min" => 1, "level_max" => 10, "hp" => 40}
      sample = {"key" => "rats", "weight" => 3, "members" => [member]}
      expect(build(:tile_npc, metadata: {"encounter_rosters" => [sample]})).to be_valid

      [{"hp" => nil}, {"level_min" => 11}, {"level_max" => 1.5}, {"level" => 4}].each do |changes|
        expect(build(:tile_npc, metadata: {"encounter_rosters" => [sample.merge("members" => [member.merge(changes)])]})).not_to be_valid
      end
      [0, 1.5, "2", 10_001].each do |weight|
        expect(build(:tile_npc, metadata: {"encounter_rosters" => [sample.merge("weight" => weight)]})).not_to be_valid
      end
    end
  end

  it "allows an inactive mine placement without inventing its interior" do
    mine = build(:tile_building, :without_destination, building_type: "location", active: false,
      metadata: {"location" => {"kind" => "mine"}})

    expect(mine).to be_valid
    expect(mine).not_to be_accessible
    mine.active = true
    expect(mine).not_to be_valid
  end
end
