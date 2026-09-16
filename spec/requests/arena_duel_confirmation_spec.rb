# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Applicant-confirmed Duel", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:room) { create(:arena_room, :trial, level_min: 1, level_max: 30) }
  let(:owner) { create(:character, level: 17, current_hp: 225, max_hp: 225) }
  let(:opponent) { create(:character, level: 24, current_hp: 750, max_hp: 750) }
  let(:handler) { Arena::ApplicationHandler.new }
  let!(:application) { create(:arena_application, applicant: owner, arena_room: room, fight_kind: :no_weapons, timeout_seconds: 120) }
  let!(:match) { handler.accept(application:, acceptor: opponent).match }

  before do
    [owner, opponent].each { |player| create(:character_position, character: player) }
  end

  it "reserves, refuses, reaccepts and explicitly starts with the original terms" do
    sign_in opponent.user
    get arena_match_path(match)
    expect(response.body).to include("Waiting for the fight to begin!", "Refuse Duel", owner.name, opponent.name)
    expect(response.body).not_to include(">Start Duel<")
    post confirm_duel_arena_match_path(match), as: :json
    expect(response).to have_http_status(:forbidden)
    expect(match.reload).to be_pending
    expect(owner.reload).not_to be_in_combat

    delete refuse_duel_arena_match_path(match), as: :json
    expect(response).to have_http_status(:ok)
    expect(match.reload).to be_cancelled
    expect(application.reload).to be_open
    expect(application.matched_with).to be_nil
    expect(match.combat_log_entries).to be_empty
    expect(opponent.unfinished_arena_result).to be_nil

    replacement = handler.accept(application:, acceptor: opponent).match
    expect(replacement).to be_awaiting_duel_confirmation
    sign_out opponent.user
    sign_in owner.user
    get arena_match_path(replacement)
    expect(response.body).to include("Start Duel")
    post confirm_duel_arena_match_path(replacement), as: :json
    expect(response).to have_http_status(:ok)
    expect(replacement.reload).to be_live
    expect(replacement.turn_timeout_seconds).to eq(120)
    expect(replacement.metadata).to include("physical_only" => true, "fight_kind" => "no_weapons", "fight_timeout_seconds" => 300)
    expect(owner.reload).to be_in_combat
    expect(opponent.reload).to be_in_combat
    count = replacement.combat_log_entries.count
    started = replacement.started_at
    post confirm_duel_arena_match_path(replacement), as: :json
    delete refuse_duel_arena_match_path(replacement), as: :json
    expect(replacement.reload).to be_live
    expect(replacement.started_at).to eq(started)
    expect(replacement.combat_log_entries.count).to eq(count)
  end

  it "rejects anonymous and foreign start/refusal" do
    post confirm_duel_arena_match_path(match)
    expect(response).to redirect_to(new_user_session_path)
    sign_in create(:character).user
    delete refuse_duel_arena_match_path(match), as: :json
    expect(response).to have_http_status(:forbidden)
    expect(match.reload).to be_awaiting_duel_confirmation
  end

  it "renders a reservation safely for a spectator without a character" do
    sign_in create(:user)
    get arena_match_path(match)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Waiting Duel", owner.name, opponent.name)
    expect(response.body).not_to include(">Start Duel<", ">Refuse Duel<")
  end

  it "revalidates HP, equipment and the deadline without partial start" do
    sign_in owner.user
    opponent.update!(current_hp: 374)
    post confirm_duel_arena_match_path(match), as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(match.reload).to be_pending
    expect(match.combat_log_entries).to be_empty
    opponent.update!(current_hp: 750)
    opponent.update!(in_combat: true)
    post confirm_duel_arena_match_path(match), as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(match.reload).to be_pending
    opponent.update!(in_combat: false)
    item = create(:inventory_item, inventory: opponent.inventory, equipped: true, equipment_slot: "head")
    post confirm_duel_arena_match_path(match), as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(match.reload).to be_pending
    item.update!(equipped: false)
    travel_to(application.expires_at, with_usec: true) do
      post confirm_duel_arena_match_path(match), as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      delete refuse_duel_arena_match_path(match), as: :json
      expect(response).to have_http_status(:ok)
      expect(application.reload).to be_expired
    end
  end

  it "prevents a worker or reload from bypassing applicant confirmation" do
    Arena::MatchStarterJob.perform_now(match.id)
    sign_in owner.user
    travel 20.seconds do
      get arena_match_path(match)
      expect(response.body).to include("Start Duel")
      expect(match.reload).to be_pending
      expect(match.combat_log_entries).to be_empty
    end
  end

  it "rejects this action on wilderness fights without touching their state" do
    wilderness = create(:arena_match, :live, arena_room: nil)
    create(:arena_participation, arena_match: wilderness, character: owner, user: owner.user)
    sign_in owner.user
    delete refuse_duel_arena_match_path(wilderness), as: :json
    expect(response).to have_http_status(:forbidden)
    expect(handler.confirm_duel(match: wilderness, character: owner, refuse: true)).not_to be_success
    expect(wilderness.reload).to be_live
  end
end
