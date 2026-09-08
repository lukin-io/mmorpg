# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City buildings", type: :request do
  let(:user) { create(:user) }
  let(:city) { create(:zone, :city_node, name: "Trading Quarter") }
  let(:character) { create(:character, user:, level: 10) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:market) { create(:city_hotspot, :read_only_city_building, zone: city) }

  before { sign_in user, scope: :user }

  it "renders the captured Market without economic mutation controls" do
    get city_building_path("market")

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Market", "Newspaper display", "Huge", "1,500 NV")
    expect(response.body).to include("read-only")
    expect(response.body).not_to include("Rent stall", "Buy listing")
  end

  it "renders the captured service-specific read-only surfaces" do
    {
      "junk_dealer" => ["Junk Dealer", "Stock was not captured"],
      "numismatics" => ["Numismatics Shop", "Ancient Alvian Coin"],
      "hospital" => ["Hospital", "Beginner healer bag", "Pharmacy"]
    }.each do |building_key, expected_text|
      market.update!(key: building_key, name: expected_text.first, action_params: {"feature" => building_key})

      get city_building_path(building_key)

      expect(response).to have_http_status(:success)
      expected_text.each { |text| expect(response.body).to include(text) }
    end
  end

  it "persists the exact building as the login resume context" do
    get city_building_path("market")

    expect(character.reload.gameplay_context).to eq(
      "name" => "city_building",
      "params" => {"building_key" => "market"}
    )
  end

  {
    "market" => "Market",
    "hospital" => "Hospital",
    "airship_station" => "Forpost Airship Station",
    "junk_dealer" => "Junk Dealer",
    "numismatics" => "Numismatics Shop"
  }.each do |building_key, title|
    it "renders the first #{title} response with its saved room presence and chat audience", :aggregate_failures do
      market.update!(key: building_key, name: title, action_params: {"feature" => building_key})
      create(:city_hotspot, :shop, zone: city)
      character.remember_gameplay_context!(name: "shop", params: {})
      previous_channel = Chat::ChannelRouter.new(user:).resolve(scope: :local)
      previous_room_players = %w[PreviousRoomOne PreviousRoomTwo].map do |name|
        create(:character, name:).tap do |player|
          create(:character_position, character: player, zone: city, x: 5, y: 5)
          create(:user_session, user: player.user)
          player.remember_gameplay_context!(name: "shop", params: {})
        end
      end
      current_room_player = create(:character, name: "CurrentRoomPlayer")
      create(:character_position, character: current_room_player, zone: city, x: 5, y: 5)
      create(:user_session, user: current_room_player.user)
      current_room_player.remember_gameplay_context!(name: "city_building", params: {building_key:})
      current_channel = Chat::ChannelRouter.new(user: current_room_player.user).resolve(scope: :local)

      get city_building_path(building_key)

      expect(response).to have_http_status(:success)
      document = Nokogiri::HTML(response.body)
      expect(document.at_css(".nl-location-text").text).to eq("#{title} [ 2 ]")
      expect(document.css(".nl-player-entry").text).to include(character.name, current_room_player.name)
      expect(document.css(".nl-player-entry").text).not_to include(*previous_room_players.map(&:name))
      expect(document.at_css("[data-player-list-location]")["data-player-list-location"]).to eq(title)
      expect(document.at_css("[data-player-list-count]")["data-player-list-count"]).to eq("2")
      expect(character.reload.gameplay_context).to eq(
        "name" => "city_building", "params" => {"building_key" => building_key}
      )
      expect(character.metadata.fetch("local_chat_context").fetch("key"))
        .to eq("zone:#{city.id}:cell:5:5:room:building:#{building_key}")
      expect(position.reload).to have_attributes(zone: city, x: 5, y: 5)

      create(:chat_message, chat_channel: previous_channel, body: "Previous room message")
      create(:chat_message, chat_channel: current_channel, body: "Current interior message")
      get local_chat_path(poll: 1)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Current interior message")
      expect(response.body).not_to include("Previous room message")
    end
  end

  it "rejects unsupported, inactive, wrong-node, and outdoor access" do
    create(:city_hotspot, :shop, zone: city)
    character.remember_gameplay_context!(name: "shop", params: {tab: "armor"})
    saved_metadata = character.reload.metadata.deep_dup

    get city_building_path("bank")
    expect(response).to redirect_to(world_path)
    expect(character.reload.metadata).to eq(saved_metadata)

    market.update!(active: false)
    get city_building_path("market")
    expect(response).to redirect_to(world_path)
    expect(character.reload.metadata).to eq(saved_metadata)

    market.update!(active: true)
    position.update!(zone: create(:zone, :city, name: "Other City Node"))
    get city_building_path("market")
    expect(response).to redirect_to(world_path)
    expect(character.reload.metadata).to eq(saved_metadata)

    position.update!(zone: create(:zone, :mvp_outdoor_region), x: 7, y: 0)
    get city_building_path("market")
    expect(response).to redirect_to(world_path)
    expect(character.reload.metadata).to eq(saved_metadata)
  end

  it "revalidates building entry after a relocation wins the character lock", :aggregate_failures do
    destination = create(:zone, :city_node, name: "Other City Node")
    exit_hotspot = create(:city_hotspot, :exit, zone: city, destination_zone: destination,
      action_params: {"destination_x" => 3, "destination_y" => 4})
    relocated = false
    relocation_result = nil
    relocated_metadata = nil

    # Complete a real node transition immediately before this request obtains
    # its character lock, reproducing the race without thread scheduling sleeps.
    allow_any_instance_of(Character).to receive(:with_lock).and_wrap_original do |original, *args, &block|
      unless relocated || original.receiver.id != character.id
        relocated = true
        relocation_result = Game::World::CityHotspotService.new(
          character: Character.find(character.id), zone: city
        ).interact!(exit_hotspot.id)
        relocated_metadata = Character.find(character.id).metadata.deep_dup
      end
      original.call(*args, &block)
    end

    get city_building_path("market")

    expect(relocated).to be(true)
    expect(relocation_result).to have_attributes(success: true)
    expect(response).to redirect_to(world_path)
    expect(response.body).not_to include("Newspaper display")
    expect(position.reload).to have_attributes(zone: destination, x: 3, y: 4)
    expect(character.reload.metadata).to eq(relocated_metadata)
    expect(character.gameplay_context).to eq("name" => "world", "params" => {})
    expect(character.metadata.fetch("local_chat_context").fetch("key"))
      .to eq("zone:#{destination.id}:cell:3:4")
  end

  it "requires authentication and does not persist building context" do
    sign_out user

    get city_building_path("market")

    expect(response).to redirect_to(new_user_session_path)
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
  end
end
