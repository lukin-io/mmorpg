# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Combat medical care", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, max_hp: 600, current_hp: 0, last_regen_tick_at: 30.seconds.ago) }
  let(:zone) { create(:zone) }
  before { create(:character_position, character:, zone:, x: 1, y: 1) }

  it "requires authentication for vitals and treatment" do
    get character_vitals_path, as: :json
    expect(response).to have_http_status(:unauthorized)
    post treat_injury_path, params: {patient_name: character.name, price: 0}
    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders server recovery and never exposes another character's vitals" do
    sign_in user
    get character_vitals_path, params: {character_id: create(:character).id}, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to include("max_hp" => 600, "current_hp" => 30)
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "keeps a defeated participant dead despite recovered underlying HP" do
    sign_in user
    character.update!(current_hp: 100)
    create(:arena_participation, arena_match: create(:arena_match, :live), character:, user:, result: :defeat)
    get character_vitals_path, as: :json
    expect(response.parsed_body["current_hp"]).to eq(0)
    expect(character.reload.current_hp).to eq(100)
  end

  it "shows medical effects, blocks combat-injury Inventory and rejects a foreign quote" do
    sign_in user
    injury = CharacterInjury.create!(character:, severity: "combat", name: "Combat injury", stat_penalty_percent: 40, expires_at: 1.day.from_now)
    get inventory_path
    expect(response).to redirect_to(medical_care_path)
    get medical_care_path
    expect(response.body).to include("Inventory unavailable", "Movement unavailable", "Combat injury")
    expect(Nokogiri::HTML(response.body).at_css("a[href='#{inventory_path}']")["data-turbo-frame"]).to eq("_top")
    stranger = create(:character)
    other_injury = CharacterInjury.create!(character: stranger, severity: "light", name: "Strain", stat_penalty_percent: 5, expires_at: 1.hour.from_now)
    quote = InjuryTreatment.create!(character_injury: other_injury, healer: character, price: 20, expires_at: 5.minutes.from_now)
    post accept_injury_treatment_path(quote)
    expect(response).to have_http_status(:not_found)
    expect(injury.reload.healed_at).to be_nil
    expect(quote.reload.status).to eq("pending")
  end

  it "declines the current patient's quote without paying or healing" do
    sign_in user
    injury = CharacterInjury.create!(character:, severity: "light", name: "Strain", stat_penalty_percent: 5, expires_at: 1.hour.from_now)
    quote = InjuryTreatment.create!(character_injury: injury, healer: create(:character), price: 20, expires_at: 5.minutes.from_now)
    post decline_injury_treatment_path(quote)
    expect(response).to redirect_to(medical_care_path)
    expect(quote.reload.status).to eq("declined")
    expect(injury.reload.healed_at).to be_nil
  end
end
