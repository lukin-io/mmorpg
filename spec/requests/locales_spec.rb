# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locales", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Locale Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "falls back to the default locale and shows recovery chrome" do
    get switch_locale_path(locale: "zz")

    expect(response).to redirect_to(world_path(locale_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-locale-denied="1"')
    expect(response.body).to include('data-locale-recovery="ru"')
    expect(response.body).to include('data-locale-recovery="en"')
    expect(session[:locale]).to eq(I18n.default_locale.to_s)
  end
end
