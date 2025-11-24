require "rails_helper"

RSpec.describe Users::ProfileStats do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:quest_chain) { create(:quest_chain) }
  let(:quest) do
    Quest.find_by(key: "stat_allocation_tutorial") ||
      create(:quest, quest_chain:, key: "stat_allocation_tutorial")
  end

  before do
    battle = create(:battle, initiator: character)
    create(:combat_log_entry, battle:, payload: {"attacker_id" => character.id, "total_damage" => 15})
    create(:quest_assignment, quest:, character:, status: :completed)
    create(:arena_ranking, character:, rating: 1450, ladder_type: "arena")
  end

  it "summarizes combat, quest, and ladder metrics" do
    stats = described_class.new(user:).as_json

    expect(stats[:damage_dealt]).to eq(15)
    expect(stats[:quests_completed]).to eq(1)
    expect(stats[:top_arena_rating]).to eq(1450)
  end
end
