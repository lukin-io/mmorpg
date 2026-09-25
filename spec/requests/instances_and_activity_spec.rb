# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Instances", type: :request do
  let(:user) { create(:user) }
  let!(:character) { create(:character, user:) }

  before { sign_in user }

  it "renders dungeon tab list" do
    get instances_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-instances-tab")
  end

  it "renders raid tab list" do
    get instances_path(tab: "raid")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-instances-tab="raid"')
  end
end

RSpec.describe "Activity", type: :request do
  let(:user) { create(:user) }
  let!(:character) { create(:character, user:) }

  before { sign_in user }

  it "renders daily contracts board" do
    get activity_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-activity-board")
  end
end
