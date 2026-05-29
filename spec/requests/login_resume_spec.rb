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
