# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Traumatologist clearance", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, perks: {"healer" => true}) }
  let(:city) { create(:zone, :city_node, name: "Trading Quarter") }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:hospital) do
    create(:city_hotspot, :read_only_city_building, zone: city, key: "hospital", name: "Hospital",
      action_params: {"feature" => "hospital"})
  end

  before { sign_in user, scope: :user }

  it "renders the Infirmary clearance control for Healer owners" do
    get city_building_path("hospital")

    expect(response).to have_http_status(:success)
    expect(response.body).to include('data-hospital-traumatologist="1"')
    expect(response.body).to include(I18n.t("game.shop.traumatologist_cta"))
  end

  it "completes clearance and unlocks Doctor II eligibility" do
    post city_building_traumatologist_path("hospital")

    expect(response).to redirect_to(city_building_path("hospital"))
    follow_redirect!
    expect(response.body).to include(I18n.t("game.shop.traumatologist_done"))
    expect(character.reload.metadata.dig("profession_unlocks", "traumatologist")).to be(true)

    rules = Game::Shop::LicenseRules.new(character:)
    template = build(:item_template, stack_limit: 1, enhancement_rules: {"license" => {
      "kind" => "doctor", "tier" => 2, "duration_days" => Game::Shop::LicenseRules::DURATIONS.fetch("doctor")[1]
    }})
    expect(rules.purchase_block_reason(template)).to be_nil
  end

  it "does not mutate another character when unauthenticated" do
    sign_out :user

    post city_building_traumatologist_path("hospital")

    expect(response).to redirect_to(new_user_session_path)
    expect(character.reload.metadata["profession_unlocks"]).to be_nil
  end
end
