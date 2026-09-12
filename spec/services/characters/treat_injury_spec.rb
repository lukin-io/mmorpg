# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::TreatInjury do
  include ActiveSupport::Testing::TimeHelpers
  let(:healer) { create(:character, perks: {"healer" => true}, allocated_stats: {"intelligence" => 29}, passive_skills: {"doctor" => 100}) }
  let(:patient) { create(:character) }
  let(:zone) { create(:zone) }
  let(:injury) { CharacterInjury.create!(character: patient, severity: "light", name: "Chest muscle hematoma", stat_penalty_percent: 5, expires_at: 30.minutes.from_now) }
  let(:template) { create(:item_template, item_type: "misc", slot: "none", durability_max: 10, requirements: {"knowledge" => 20, "doctor" => 100}, stat_modifiers: {"heals_injury" => "light"}) }
  let(:bag) { create(:inventory_item, inventory: healer.inventory, item_template: template) }
  let(:service) { described_class.new(healer:, injury:, bag:) }

  before do
    [healer, patient].each do |character|
      create(:character_position, character:, zone:, x: 1, y: 1)
      character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 1000)
      character.user.currency_wallet.update!(nv_balance: 1000)
    end
    license_template = create(:item_template, item_type: "misc", slot: "none")
    offer = create(:world_action_offer, character: healer, zone:, x: 1, y: 1, action_type: "shop_buy", target: license_template)
    healer.character_licenses.create!(item_template: license_template, world_action_offer: offer, kind: "doctor", tier: 1, name: "Doctor license", starts_at: 1.day.ago, expires_at: 1.day.from_now)
  end

  it "heals free treatment immediately and spends one use without transferring money" do
    result = service.request!(price: 0)
    expect(result.status).to eq("completed")
    expect(injury.reload.healed_at).to be_present
    expect(bag.reload.current_durability).to eq(9)
    expect(patient.user.currency_wallet.reload.nv_balance).to eq(1000)
    expect(GameEvent.where("event_key LIKE ?", "treatment:#{result.id}:completed:%").count).to eq(2)
  end

  it "quotes a paid treatment, requires the patient and commits only once" do
    treatment = service.request!(price: 50)
    expect(injury.reload.healed_at).to be_nil
    expect(bag.reload.current_durability).to eq(10)
    expect { service.accept!(treatment:, patient: healer) }.to raise_error(described_class::Unavailable)
    2.times { service.accept!(treatment:, patient:) }
    expect(patient.user.currency_wallet.reload.nv_balance).to eq(950)
    expect(healer.user.currency_wallet.reload.nv_balance).to eq(1050)
    expect(bag.reload.current_durability).to eq(9)
  end

  it "rejects expired, moved, broke and unlicensed acceptance without partial state" do
    treatment = service.request!(price: 80)
    patient.position.update!(x: 2)
    expect { service.accept!(treatment:, patient:) }.to raise_error(described_class::Unavailable, /same cell/)
    patient.position.update!(x: 1)
    patient.user.currency_wallet.update!(nv_balance: 0)
    expect { service.accept!(treatment:, patient:) }.to raise_error(described_class::Unavailable, /NV/)
    healer.character_licenses.update_all(expires_at: 1.second.ago)
    expect { service.accept!(treatment:, patient:) }.to raise_error(described_class::Unavailable, /license/)
    expect(injury.reload.healed_at).to be_nil
    expect(bag.reload.current_durability).to eq(10)
  end

  it "rejects a foreign or exhausted bag and the published price ceiling" do
    expect { service.request!(price: 81) }.to raise_error(described_class::Unavailable)
    bag.update!(properties: {"current_durability" => 0})
    expect { service.request!(price: 0) }.to raise_error(described_class::Unavailable, /broken/)
    bag.update!(inventory: patient.inventory, properties: {})
    expect { service.request!(price: 0) }.to raise_error(described_class::Unavailable, /bag/)
  end

  it "expires exactly at the quoted deadline and injury deadline" do
    treatment = service.request!(price: 50)
    travel_to treatment.expires_at, with_usec: true do
      expect { service.accept!(treatment:, patient:) }.to raise_error(described_class::Unavailable, /expired/)
    end
    travel_to injury.expires_at, with_usec: true do
      expect(injury).not_to be_active
      expect { service.request!(price: 0) }.to raise_error(described_class::Unavailable, /healed/)
    end
  end

  %w[light medium heavy].each do |severity|
    it "heals a randomly awarded #{severity} injury through the shared healer workflow" do
      match = create(:arena_match, status: :completed, trauma_percent: 10)
      create(:arena_participation, arena_match: match, character: patient, user: patient.user, result: :defeat)
      rng = instance_double(Random)
      allow(rng).to receive(:rand).with(100).and_return(0, {"light" => 0, "medium" => 80, "heavy" => 98}.fetch(severity))
      awarded = Arena::InjuryAwarder.new(match:, rng:).call.sole
      expect(awarded.severity).to eq(severity)
      template.update!(stat_modifiers: {"heals_injury" => severity})
      treatment = described_class.new(healer:, injury: awarded, bag:).request!(price: 0)
      expect(treatment.status).to eq("completed")
      expect(awarded.reload).not_to be_active
      expect(awarded).not_to be_blocks_movement
      expect(bag.reload.current_durability).to eq(9)
      expect(patient.user.currency_wallet.reload.nv_balance).to eq(1000)
    end
  end
end
