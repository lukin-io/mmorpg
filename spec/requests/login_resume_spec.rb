# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Login resume", type: :request do
  def log_in(user, password: "Password123!")
    post user_session_path,
      params: {
        user: {
          email: user.email,
          password: password
        }
      }
  end

  it "sends playable accounts directly to the world at their persisted cell" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    zone = create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20)
    character = create(:character, user: user)

    create(:character_position, character: character, zone: zone, x: 7, y: 9)

    log_in(user)

    expect(response).to redirect_to(world_path)

    follow_redirect!

    expect(response.body).to include("Outpost Surroundings")
    expect(response.body).to include('data-nl-world-map-player-x-value="7"')
    expect(response.body).to include('data-nl-world-map-player-y-value="9"')
    expect(response.body).to include("[7, 9]")
  end

  it "keeps the finalized outdoor cell across logout and another login" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    region = create(:zone, :mvp_outdoor_region, name: "Persistent Region")
    character = create(:character, user:)
    position = create(:character_position, character:, zone: region, x: 742, y: 318)

    log_in(user)
    follow_redirect!
    delete destroy_user_session_path

    expect(position.reload).to have_attributes(zone: region, x: 742, y: 318)

    log_in(user)
    expect(response).to redirect_to(world_path)
    follow_redirect!

    expect(response.body).to include("Persistent Region", "[742, 318]")
    expect(position.reload).to have_attributes(zone: region, x: 742, y: 318)
  end

  it "keeps the player inside the same shop state across logout and login" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    city = create(:zone, :city, name: "Persistent City")
    character = create(:character, user:, level: 10)
    position = create(:character_position, character:, zone: city, x: 4, y: 6)
    create(:city_hotspot, :shop, zone: city, required_level: 1)

    sign_in user, scope: :user
    get shop_path(mode: "sell", category: "jewelry", min_price: 10)
    expect(response).to have_http_status(:success)
    delete destroy_user_session_path

    log_in(user)

    expect(response).to redirect_to(shop_path(mode: "sell", category: "jewelry", min_price: "10"))
    expect(position.reload).to have_attributes(zone: city, x: 4, y: 6)

    follow_redirect!
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Shop", "Sell", "Jewelry")
  end

  it "resumes the city surface after the player leaves the shop for the city" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    city = create(:zone, :city, name: "Resume City", metadata: {"description" => "Resume City Square"})
    character = create(:character, user:, level: 10)
    create(:character_position, character:, zone: city, x: 5, y: 5)
    create(:city_hotspot, :shop, zone: city, required_level: 1)

    sign_in user, scope: :user
    get shop_path
    get world_path
    delete destroy_user_session_path

    log_in(user)

    expect(response).to redirect_to(world_path)
    follow_redirect!
    expect(response.body).to include('aria-label="Resume City city map"')
    expect(response.body).to include("nl-city-scene-image")
  end

  it "keeps the player inside the same documented city building across logout and login" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    city = create(:zone, :city_node, name: "Resume Trading Quarter")
    character = create(:character, user:, level: 10)
    position = create(:character_position, character:, zone: city, x: 5, y: 5)
    create(:city_hotspot, :read_only_city_building, zone: city)

    sign_in user, scope: :user
    get city_building_path("market")
    expect(response).to have_http_status(:success)
    delete destroy_user_session_path

    log_in(user)

    expect(response).to redirect_to(city_building_path("market"))
    expect(position.reload).to have_attributes(zone: city, x: 5, y: 5)
    follow_redirect!
    expect(response.body).to include("Market", "read-only")
  end

  it "falls back to the persisted world position for stale or malformed interior context" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    region = create(:zone, :mvp_outdoor_region, name: "Fallback Region")
    character = create(
      :character,
      user:,
      metadata: {
        Character::GAMEPLAY_CONTEXT_KEY => {
          "name" => "shop",
          "params" => {"return_to" => "https://example.invalid"}
        }
      }
    )
    create(:character_position, character:, zone: region, x: 8, y: 9)

    log_in(user)

    expect(response).to redirect_to(world_path)
    expect(response.location).not_to include("example.invalid")
  end

  it "never resumes another user's shop context" do
    shop_owner = create(:user)
    city = create(:zone, :city, name: "Owner City")
    owner_character = create(:character, :resuming_shop, user: shop_owner, level: 10)
    create(:character_position, character: owner_character, zone: city, x: 3, y: 3)
    create(:city_hotspot, :shop, zone: city)

    other_user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    region = create(:zone, :mvp_outdoor_region, name: "Other Region")
    other_character = create(:character, user: other_user)
    create(:character_position, character: other_character, zone: region, x: 12, y: 14)

    log_in(other_user)

    expect(response).to redirect_to(world_path)
    follow_redirect!
    expect(response.body).to include("Other Region", "[12, 14]")
    expect(response.body).not_to include("Owner City")
  end

  it "does not resume or mutate location state after failed authentication" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    character = create(:character, :resuming_shop, user:)
    original_context = character.gameplay_context

    log_in(user, password: "incorrect-password")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response).not_to redirect_to(shop_path)
    expect(character.reload.gameplay_context).to eq(original_context)

    get shop_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "boots accounts without a character into the world" do
    user = create(:user, password: "Password123!", password_confirmation: "Password123!")
    zone = create(:zone, name: "Outpost", location_type: "city", width: 20, height: 20)
    create(:spawn_point, zone: zone, x: 5, y: 5, default_entry: true)

    log_in(user)

    expect(response).to redirect_to(world_path)

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(user.characters.reload.count).to eq(1)
    expect(user.character.position.zone.name).to eq("Outpost")
  end
end
