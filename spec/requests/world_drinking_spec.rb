# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Current-cell drinking", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let(:character) { create(:character, fatigue_percent: 7, fatigue_updated_at: Time.current, passive_skills: {}, perks: {}) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let!(:pond) do
    create(:map_tile_template, zone: zone.name, x: 5, y: 5, metadata: {
      "local_actions" => [{"type" => "drinking", "source_id" => "dri"},
        {"type" => "resource_search", "source_id" => "look"}]
    })
  end

  around { |example| freeze_time { example.run } }
  before { sign_in character.user, scope: :user }

  def offer_drink
    get world_path
    WorldActionOffer.offered.find_by!(character:, action_type: "drink")
  end

  def drink(offer, extra: {})
    post perform_local_action_world_path, params: {
      tile_id: pond.id, local_action_type: "drinking", action_key: offer.action_key
    }.merge(extra)
  end

  it "offers Drink at the fatigue lock boundary and uses server recovery despite forged values" do
    character.update!(fatigue_percent: 86)
    offer = offer_drink
    expect(WorldActionOffer.offered.where(character:).pluck(:action_type)).to eq(["drink"])
    expect(MovementCommand.offered.where(character:)).to be_empty

    drink(offer, extra: {fatigue_recovery_points: 100, duration_seconds: 0})

    expect(response).to redirect_to(world_path)
    expect(character.reload.fatigue_percent).to eq(84)
    expect(offer.reload.local_action_ends_at).to eq(Time.current + 60.seconds)
    follow_redirect!
    expect(Nokogiri::HTML(response.body).css("dialog").text).to include("Everything went well.")
    expect(WorldActionOffer.offered.where(character:)).to be_empty
    expect(MovementCommand.offered.where(character:)).to be_empty
  end

  it "retains the original recovery and deadline across duplicate requests and result reloads" do
    offer = offer_drink
    drink(offer)
    deadline = offer.reload.local_action_ends_at
    follow_redirect!
    get world_path
    expect(Nokogiri::HTML(response.body).css("dialog")).to be_empty
    expect(character.reload.fatigue_percent).to eq(5)

    [10, 70].each do |seconds|
      travel_to(offer.accepted_at + seconds)
      drink(offer)
      expect(character.reload.fatigue_percent).to eq(5)
      expect(offer.reload.local_action_ends_at).to eq(deadline)
    end
  end

  it "does not allow a removed action or another cell to recover fatigue" do
    offer = offer_drink
    pond.update!(metadata: {})
    drink(offer)
    expect(character.reload.fatigue_percent).to eq(7)
    expect(offer.reload.local_action_ends_at).to be_nil

    other_pond = create(:map_tile_template, zone: zone.name, x: 6, y: 5,
      metadata: {"local_actions" => [{"type" => "drinking", "source_id" => "dri"}]})
    distant_offer = create(:world_action_offer, character:, zone:, x: 5, y: 5, action_type: "drink", target: other_pond)
    drink(distant_offer, extra: {tile_id: other_pond.id})
    expect(character.reload.fatigue_percent).to eq(7)
    expect(distant_offer.reload.local_action_ends_at).to be_nil
  end

  it "rejects a foreign action key without touching either player's state" do
    foreign = create(:world_action_offer, zone:, x: 5, y: 5, action_type: "drink", target: pond)
    drink(foreign)

    expect(response).to redirect_to(root_path)
    expect(foreign.reload).to be_offered
    expect(character.reload.fatigue_percent).to eq(7)
  end

  it "keeps walking and Inventory locked until the persisted sip deadline" do
    offer = offer_drink
    move = MovementCommand.offered.find_by!(character:, direction: "east")
    drink(offer)
    post move_world_path, params: {action_key: move.action_key, direction: "east", target_x: 6, target_y: 5}
    get inventory_path

    expect(response).to redirect_to(world_path)
    expect(position.reload).to have_attributes(x: 5, y: 5)
    expect(move.reload).to be_cancelled
    expect(character.reload.fatigue_percent).to eq(5)

    travel_to(offer.reload.local_action_ends_at)
    get world_path
    expect(offer.reload).to be_completed
    expect(WorldActionOffer.offered.where(character:, action_type: "drink")).to exist
    expect(MovementCommand.offered.where(character:)).to exist
    expect(character.reload.fatigue_percent).to eq(5)
  end

  it "requires authentication before accepting a sip" do
    offer = offer_drink
    sign_out character.user
    drink(offer)

    expect(response).to redirect_to(new_user_session_path)
    expect(offer.reload).to be_offered
    expect(character.reload.fatigue_percent).to eq(7)
  end
end
