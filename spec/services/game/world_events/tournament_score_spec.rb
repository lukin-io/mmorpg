# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::WorldEvents::TournamentScore do
  it "records fish scores and finalizes a ranking announcement" do
    character = create(:character, name: "Angler")
    event = WorldLiveEvent.create!(
      kind: "tournament_fish",
      status: "active",
      title_ru: "Турнир рыбаков",
      title_en: "Fish",
      body_ru: "go",
      body_en: "go",
      payload: {"scores" => {}},
      starts_at: Time.current,
      ends_at: 1.hour.from_now,
      event_key: "fish-test-#{SecureRandom.hex(4)}"
    )

    expect(described_class.record_fish!(character:, amount: 3).ok).to eq(true)
    event.reload
    expect(event.payload.dig("scores", character.id.to_s)).to eq(3)

    expect {
      event.end!
    }.to change(GameEvent.where(event_type: :world_announcement), :count).by(1)

    expect(event.reload.payload["finalized"]).to eq(true)
  end

  it "grants season XP when recording a fish score during an active season" do
    character = create(:character, name: "Sealer")
    WorldLiveEvent.create!(
      kind: "tournament_fish",
      status: "active",
      title_ru: "Турнир",
      title_en: "Fish",
      body_ru: "go",
      body_en: "go",
      payload: {"scores" => {}},
      starts_at: Time.current,
      ends_at: 1.hour.from_now,
      event_key: "fish-xp-#{SecureRandom.hex(4)}"
    )
    allow(Game::Seasons::Catalog).to receive(:active?).and_return(true)
    allow(Game::Seasons::Catalog).to receive(:current).and_return({"xp_per_pulse_hour" => 10})
    progress = instance_double(Game::Seasons::Progress, add_xp!: true)
    allow(Game::Seasons::Progress).to receive(:new).with(character:).and_return(progress)

    expect(progress).to receive(:add_xp!).with(10)
    expect(described_class.record_fish!(character:, amount: 1).ok).to eq(true)
  end
end
