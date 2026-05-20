# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Events::QuestOrchestrator do
  let(:game_event) { create(:game_event, slug: "frostfall") }
  let(:event_instance) do
    create(:event_instance,
      game_event:,
      metadata: {"featured_clan" => "Frost Guard", "resource_focus" => "ashen_ore", "world_reskin" => "winter"},
      temporary_npc_keys: ["npc_herald"])
  end
  let(:dynamic_generator) { instance_double(Game::Quests::DynamicQuestGenerator, generate!: []) }
  let(:orchestrator) do
    described_class.new(event_instance, dynamic_generator:)
  end

  it "assigns dynamic quests and annotates world state" do
    character = create(:character)

    orchestrator.prepare!(characters: Character.where(id: character.id))

    expect(dynamic_generator).to have_received(:generate!).with(
      character:,
      triggers: hash_including(
        event_key: "frostfall",
        clan_controlled: "Frost Guard",
        resource_shortage: "ashen_ore"
      )
    )
    expect(event_instance.reload.metadata["temporary_npc_keys"]).to include("npc_herald")
  end
end
