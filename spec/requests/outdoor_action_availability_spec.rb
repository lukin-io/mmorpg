# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Outdoor action availability", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:character) { create(:character, user:, stat_points_available: 5) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }
  let!(:village) { create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6) }
  let(:inventory) { character.inventory }
  let(:wallet) { user.currency_wallet }
  let(:template) do
    create(:item_template, base_price: 40, weight: 2,
      enhancement_rules: {"shop_stock" => {"current" => 5, "max" => 10}})
  end
  let(:item) { create(:inventory_item, inventory:, item_template: template, quantity: 2, weight: 2) }

  before do
    sign_in user, scope: :user
    Game::World::ResumeContext.new(character:).remember_world!
  end

  %i[travel look].each do |work|
    context "during accepted #{work}" do
      before { start_work(work) }

      %i[inventory profile stats skills perks shop village].each do |surface|
        it "rejects direct #{surface} navigation without replacing the saved world context" do
          context_before = character.reload.gameplay_context

          expect { get surface_path(surface) }.not_to change(WorldActionOffer, :count)

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to(world_path)
          expect(character.reload.gameplay_context).to eq(context_before)
          expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
        end
      end

      it "rejects a Turbo equip intent without changing equipment" do
        post equip_inventory_path, params: {item_id: item.id},
          headers: {"ACCEPT" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(world_path)
        expect(item.reload).to have_attributes(equipped: false, equipment_slot: nil)
      end

      it "rejects the separate item discard endpoint without consuming the stack" do
        inventory.update!(current_weight: 4)

        delete inventory_item_path(item)

        expect(response).to redirect_to(world_path)
        expect(item.reload.quantity).to eq(2)
        expect(inventory.reload.current_weight).to eq(4)
      end

      it "rejects repeated direct purchases without money, item, or stock changes" do
        wallet.update!(nv_balance: 200)
        template

        2.times do
          post buy_shop_path, params: {item_template_id: template.id, quantity: 1}
          expect(response).to redirect_to(world_path)
        end

        expect(wallet.reload.nv_balance).to eq(200)
        expect(wallet.currency_transactions).to be_empty
        expect(inventory.inventory_items).to be_empty
        expect(template.reload.shop_stock_current).to eq(5)
      end

      it "rejects a direct sale without transferring items or currency" do
        wallet.update!(nv_balance: 200)
        inventory.update!(current_weight: 4)

        post sell_shop_path, params: {item_id: item.id, quantity: 1}

        expect(response).to redirect_to(world_path)
        expect(wallet.reload.nv_balance).to eq(200)
        expect(wallet.currency_transactions).to be_empty
        expect(item.reload.quantity).to eq(2)
        expect(inventory.reload.current_weight).to eq(4)
        expect(template.reload.shop_stock_current).to eq(5)
      end

      it "rejects direct progression mutation without spending points" do
        patch stats_character_path(character), params: {allocated_stats: {strength: 1}}

        expect(response).to redirect_to(world_path)
        expect(character.reload).to have_attributes(stat_points_available: 5, allocated_stats: {})
      end

      it "leaves public profiles and the own public JSON response available" do
        other_character = create(:character)

        get player_path(name: other_character.name)
        expect(response).to have_http_status(:ok)

        get player_path(name: character.name, format: :json)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  it "reconciles due travel before validating an old Shop URL" do
    command = start_work(:travel)
    travel_to(command.ends_at, with_usec: true) do
      get shop_path
    end

    expect(response).to redirect_to(world_path)
    expect(command.reload).to be_completed
    expect(position.reload).to have_attributes(zone:, x: 5, y: 6)
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
  end

  it "completes an elapsed Look timer and allows the waiting inventory request" do
    offer = start_work(:look)
    travel_to(offer.local_action_ends_at, with_usec: true) do
      get inventory_path
    end

    expect(response).to have_http_status(:ok)
    expect(offer.reload).to be_completed
  end

  %i[profile stats skills perks].each do |surface|
    it "renders completed travel fatigue from the current character on #{surface}" do
      command = start_work(:travel)
      command.update!(metadata: {"fatigue_gain" => 2})

      travel_to(command.ends_at, with_usec: true) do
        get surface_path(surface)
      end

      expect(response).to have_http_status(:ok)
      expect(command.reload).to be_completed
      expect(character.reload.fatigue_percent).to eq(2)
      expect(Nokogiri::HTML(response.body).at_css(".nl-sheet-chip--fatigue").text).to eq("2%")
    end
  end

  it "reserves inventory during every active fight even without outdoor work" do
    match = create(:arena_match, :live)
    create(:arena_participation, arena_match: match, character:, user:)

    get inventory_path

    expect(response).to redirect_to(arena_match_path(match))
    expect(response).to have_http_status(:see_other)
    expect(match.reload).to be_live
  end

  def start_work(work)
    if work == :travel
      create(:movement_command, :moving, character:, zone:, direction: "east",
        from_x: 4, from_y: 6, target_x: 5, target_y: 6)
    else
      create(:world_action_offer, :accepted, character:, zone:, x: 4, y: 6,
        metadata: {
          "local_action_ends_at" => 28.seconds.from_now.iso8601(6),
          "local_action_result" => "There is no useful vegetation in this area."
        })
    end
  end

  def surface_path(surface)
    case surface
    when :inventory then inventory_path
    when :profile then player_path(name: character.name)
    when :stats then stats_character_path(character)
    when :skills then skills_character_path(character)
    when :perks then perks_character_path(character)
    when :shop then shop_path
    when :village then world_location_path(village.location_key)
    end
  end
end
