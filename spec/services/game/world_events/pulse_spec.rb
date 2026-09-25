# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::WorldEvents::Pulse do
  before do
    WorldFortress.active.delete_all
    WorldLiveEvent.delete_all
  end

  it "lights a sector siege on an active fortress when none are under siege" do
    fort = WorldFortress.create!(
      zone: "Пепельный Берег",
      x: 3,
      y: 4,
      fortress_key: "pulse_fort",
      name: "Пульс-Редут",
      kind: "fortress",
      active: true
    )

    events = described_class.new(rng: Random.new(1)).call

    fort.reload
    expect(fort.under_siege?).to be(true)
    expect(fort.metadata["pulse_siege"]).to be(true)
    expect(events.map(&:kind)).to include("sector_siege")
    expect(WorldLiveEvent.active.of_kind("sector_siege").count).to eq(1)

    # Idempotent while siege is live
    described_class.new(rng: Random.new(2)).call
    expect(WorldLiveEvent.active.of_kind("sector_siege").count).to eq(1)
  end
end
