# frozen_string_literal: true

require "rails_helper"

RSpec.describe CharacterLicense, type: :model do
  let(:character) { create(:character) }
  let(:template) { create(:item_template) }
  let(:zone) { create(:zone) }
  let(:offer) do
    WorldActionOffer.create!(character:, zone:, x: 0, y: 0, target: template,
      action_type: "shop_buy", action_key: SecureRandom.hex(16), expires_at: 10.minutes.from_now)
  end
  let(:starts_at) { Time.zone.parse("2026-09-09 12:00:00") }
  let(:license) do
    described_class.create!(character:, item_template: template, world_action_offer: offer,
      kind: "trading", tier: 1, name: "Trading I", starts_at:, expires_at: starts_at + 3.days)
  end

  it "is active from activation through the instant before its persisted expiry" do
    expect(license.active?(at: starts_at - 1.second)).to be(false)
    expect(license.active?(at: starts_at)).to be(true)
    expect(license.active?(at: license.expires_at - 1.second)).to be(true)
    expect(license.active?(at: license.expires_at)).to be(false)
    expect(license.active?(at: license.expires_at + 1.second)).to be(false)
    expect(described_class.active_at(starts_at)).to include(license)
    expect(described_class.active_at(license.expires_at)).not_to include(license)
  end

  it "retains granted name and expiry when the shop template changes" do
    license
    template.update!(name: "Updated title", enhancement_rules: {"license" => {"duration_days" => 30}})
    expect(license.reload).to have_attributes(name: "Trading I", expires_at: starts_at + 3.days)
  end

  it "requires a positive period and an explicitly supported permission" do
    license.assign_attributes(expires_at: starts_at, tier: 4, kind: "unlimited")
    expect(license).not_to be_valid
    expect(license.errors.attribute_names).to include(:expires_at, :tier, :kind)
  end

  it "rejects a foreign character or a different target on the purchase offer" do
    license.character = create(:character)
    expect(license).not_to be_valid
    expect(license.errors.attribute_names).to include(:world_action_offer)
    license.character = character
    license.item_template = create(:item_template)
    expect(license).not_to be_valid
  end

  it "prevents duplicate grants from one purchase at model and database boundaries" do
    original = license
    duplicate = original.dup
    expect(duplicate).not_to be_valid
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
