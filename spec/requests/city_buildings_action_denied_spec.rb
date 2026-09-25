# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City building action denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:city) { create(:zone, :city_node, name: "Action Deny Quarter") }
  let(:character) { create(:character, user:, level: 10) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:shop) { create(:city_hotspot, :shop, zone: city) }

  before { sign_in user, scope: :user }

  it "recovers when resting in a building that does not offer rest" do
    post city_building_rest_path("shop")

    expect(response).to redirect_to(world_path(building_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-building-denied="1"')
  end

  it "recovers when a bank vault transfer fails" do
    create(:city_hotspot, :building, zone: city, key: "bank", name: "Bank",
      action_params: {"feature" => "bank"})

    post city_building_bank_path("bank"), params: {bank_action: "deposit", amount: 0}

    expect(response).to redirect_to(city_building_path("bank", bank_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-bank-denied="1"')
    expect(response.body).to include('data-bank-recovery="world"')
    expect(response.body).to include('data-bank-recovery="bank"')
  end

  it "recovers when a post office note save fails" do
    create(:city_hotspot, :building, zone: city, key: "post", name: "Post",
      action_params: {"feature" => "post"})

    post city_building_post_path("post"), params: {body: "   "}

    expect(response).to redirect_to(city_building_path("post", post_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-post-denied="1"')
    expect(response.body).to include('data-post-recovery="world"')
    expect(response.body).to include('data-post-recovery="post"')
  end

  it "recovers when a souvenir purchase fails" do
    create(:city_hotspot, :building, zone: city, key: "souvenir_shop", name: "Souvenir",
      action_params: {"feature" => "souvenir_shop"})

    post city_building_souvenir_path("souvenir_shop"), params: {item_key: "__missing_ashen_souvenir__"}

    expect(response).to redirect_to(city_building_path("souvenir_shop", souvenir_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-souvenir-denied="1"')
    expect(response.body).to include('data-souvenir-recovery="world"')
    expect(response.body).to include('data-souvenir-recovery="souvenir"')
  end

  it "recovers when a junk buyback fails" do
    create(:city_hotspot, :building, zone: city, key: "junk_dealer", name: "Junk",
      action_params: {"feature" => "junk_dealer"})

    post city_building_sell_path("junk_dealer"), params: {item_key: "__missing_ashen_junk__", quantity: 1}

    expect(response).to redirect_to(city_building_path("junk_dealer", junk_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-junk-denied="1"')
    expect(response.body).to include('data-junk-recovery="world"')
    expect(response.body).to include('data-junk-recovery="junk"')
  end

  it "recovers when a temple blessing fails" do
    create(:city_hotspot, :building, zone: city, key: "temple", name: "Temple",
      action_params: {"feature" => "temple"})

    post city_building_bless_path("temple")

    expect(response).to redirect_to(city_building_path("temple", temple_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-temple-denied="1"')
    expect(response.body).to include('data-temple-recovery="world"')
    expect(response.body).to include('data-temple-recovery="temple"')
  end

  it "recovers when a city obelisk desk action fails" do
    create(:city_hotspot, :building, zone: city, key: "obelisk", name: "Obelisk",
      action_params: {"feature" => "obelisk"})

    post city_building_obelisk_path("obelisk"), params: {obelisk_action: "__bad__"}

    expect(response).to redirect_to(city_building_path("obelisk", obelisk_desk_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-obelisk-desk-denied="1"')
    expect(response.body).to include('data-obelisk-recovery="world"')
    expect(response.body).to include('data-obelisk-recovery="obelisk"')
  end

  it "recovers when a law alignment pledge fails" do
    create(:city_hotspot, :building, zone: city, key: "law_abode", name: "Law",
      action_params: {"feature" => "law_abode"})

    post city_building_law_path("law_abode"), params: {alignment: "__bad_ashen_alignment__"}

    expect(response).to redirect_to(city_building_path("law_abode", law_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-law-denied="1"')
    expect(response.body).to include('data-law-recovery="world"')
    expect(response.body).to include('data-law-recovery="law"')
  end

  it "recovers when an Infirmary traumatologist step fails" do
    create(:city_hotspot, :building, zone: city, key: "hospital", name: "Hospital",
      action_params: {"feature" => "hospital"})

    post city_building_traumatologist_path("hospital")

    expect(response).to redirect_to(city_building_path("hospital", hospital_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-hospital-denied="1"')
    expect(response.body).to include('data-hospital-recovery="world"')
    expect(response.body).to include('data-hospital-recovery="hospital"')
  end

  it "recovers when a workshop craft fails" do
    create(:city_hotspot, :building, zone: city, key: "workshop", name: "Workshop",
      action_params: {"feature" => "workshop"})

    post city_building_craft_path("workshop"), params: {recipe_key: "__missing_ashen_recipe__"}

    expect(response).to redirect_to(city_building_path("workshop", craft_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-craft-denied="1"')
    expect(response.body).to include('data-workshop-recovery="world"')
    expect(response.body).to include('data-workshop-recovery="workshop"')
  end

  it "recovers when a tavern rest fails because the character is already full" do
    create(:city_hotspot, :building, zone: city, key: "tavern", name: "Tavern",
      action_params: {"feature" => "tavern"})
    character.update!(current_hp: character.effective_max_hp, current_mp: character.effective_max_mp)

    post city_building_rest_path("tavern")

    expect(response).to redirect_to(city_building_path("tavern", rest_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-rest-denied="1"')
    expect(response.body).to include('data-tavern-recovery="world"')
    expect(response.body).to include('data-tavern-recovery="tavern"')
  end
end
