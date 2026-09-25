# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Quests", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Quest Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before do
    Game::Quests::Catalog.reload!
    sign_in user, scope: :user
  end

  it "redirects unknown accept to the journal with quest_denied recovery" do
    post accept_quest_path("definitely_missing_ashen_quest")

    expect(response).to redirect_to(quests_path(quest_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-quest-denied="1"')
    expect(response.body).to include('data-quest-recovery="world"').or include('data-quest-recovery="city_hall"')
  end

  it "filters the journal by status query" do
    get quests_path(status: "locked")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-quest-filters="1"')
    expect(response.body).to include('data-quest-filter="locked"')
    # Locked filter should not render available accept buttons when any locked rows exist,
    # and must not 500 when the journal is empty for that status.
    expect(response.body).not_to include("Translation missing")
  end
end
