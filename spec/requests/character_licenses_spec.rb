# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Character licenses", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone) }
  let(:template) { create(:item_template) }
  let!(:position) { create(:character_position, character:, zone:, x: 0, y: 0) }

  before { sign_in user, scope: :user }

  def grant(owner: character, name: "Trading I", starts_at: 1.hour.ago, expires_at: 3.days.from_now)
    offer = create(:world_action_offer, :completed, character: owner, zone:, x: 0, y: 0,
      action_type: "shop_buy", target: template)
    CharacterLicense.create!(character: owner, item_template: template, world_action_offer: offer,
      kind: "trading", tier: 1, name:, starts_at:, expires_at:)
  end

  it "requires authentication before disclosing licenses" do
    grant
    sign_out :user

    get character_licenses_path

    expect(response).to redirect_to(new_user_session_path)
    expect(response.body).not_to include("Trading I")
  end

  it "shows the observed empty state in the game shell with a reachable Abilities link" do
    get character_licenses_path

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css('[aria-label="Abilities"]')).to be_present
    expect(html.at_css('a[aria-label="Abilities"]')["href"]).to eq(character_licenses_path)
    expect(html.at_css('.nl-profile-tabs [aria-current="page"]').text).to eq("Your licenses")
    expect(html.at_css("#character-licenses-heading").text).to eq("Your licenses")
    expect(response.body).to include("You have no licenses.")
    expect(html.at_css('meta[name="turbo-cache-control"]')["content"]).to eq("no-cache")
  end

  it "renders purchased snapshots and expiration without creating inventory items" do
    license = grant
    template.update!(name: "Changed shop title")
    count = character.inventory.inventory_items.count

    get character_licenses_path

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    row = html.at_css("#character_license_#{license.id}")
    expect(row.text).to include("Trading I", "Trading", "Level:", "1", "Valid until:")
    expect(row.at_css("time")["datetime"]).to eq(license.expires_at.iso8601)
    expect(row.text).not_to include("Changed shop title")
    expect(row.css("form, button, input")).to be_empty
    expect(character.inventory.inventory_items.count).to eq(count)
  end

  it "ignores foreign character, item and license identifiers in query parameters" do
    own_license = grant
    other = create(:character)
    foreign_license = grant(owner: other, name: "Private foreign license")

    get character_licenses_path, params: {character_id: other.id, id: foreign_license.id, item_template_id: template.id}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("character_license_#{own_license.id}")
    expect(response.body).not_to include("Private foreign license", "character_license_#{foreign_license.id}")
  end

  it "restores the purchased grant after a fresh sign-in without extending it" do
    license = grant
    original_expiry = license.expires_at
    get character_licenses_path
    sign_out :user
    sign_in user, scope: :user

    get character_licenses_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("character_license_#{license.id}")
    expect(license.reload.expires_at).to eq(original_expiry)
  end

  it "stops displaying a license exactly at expiry while preserving the purchase record" do
    freeze_time do
      license = grant(expires_at: 1.second.from_now)
      get character_licenses_path
      expect(response.body).to include("character_license_#{license.id}")

      travel 1.second
      get character_licenses_path
      expect(response.body).to include("You have no licenses.")
      expect(response.body).not_to include("character_license_#{license.id}")

      travel 1.second
      get character_licenses_path
      expect(response.body).to include("You have no licenses.")
      expect(CharacterLicense.exists?(license.id)).to be true
    end
  end

  it "does not expose a future permission before its activation time" do
    freeze_time do
      license = grant(starts_at: 1.second.from_now)
      get character_licenses_path
      expect(response.body).to include("You have no licenses.")

      travel 1.second
      get character_licenses_path
      expect(response.body).to include("character_license_#{license.id}")
    end
  end

  it "bounds the current grants shown without deleting older purchase records" do
    licenses = 101.times.map { |index| grant(name: "Trading grant #{index}", expires_at: (index + 1).days.from_now) }

    get character_licenses_path

    rows = Nokogiri::HTML(response.body).css(".nl-profile-license-list > li")
    expect(rows.size).to eq(100)
    expect(rows.first["id"]).to eq("character_license_#{licenses.first.id}")
    expect(response.body).not_to include("character_license_#{licenses.last.id}")
    expect(character.character_licenses.count).to eq(101)
  end

  it "links the owner's profile to their licenses without exposing the link on visitor profiles" do
    get player_path(name: character.name)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css(".nl-profile-tabs a[href='#{character_licenses_path}']").text).to eq("Your licenses")

    get player_path(name: create(:character).name)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css(".nl-profile-tabs a[href='#{character_licenses_path}']")).to be_nil
  end
end
