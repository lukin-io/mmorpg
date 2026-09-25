# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Pets::Board do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }

  subject(:board) { described_class.new(character:) }

  before { user.currency_wallet.update!(nv_balance: 5_000) }

  it "grants starter pets and equips armor-fang by default" do
    rows = board.rows
    expect(rows.map { |row| row[:pet].pet_key }).to include("armor-fang", "bell-moth")
    expect(board.equipped_pet.pet_key).to eq("armor-fang")
  end

  it "equips one pet at a time" do
    board.ensure_starters!
    result = board.equip!(pet_key: "bell-moth")
    expect(result.ok).to be true
    expect(character.character_pets.equipped.pluck(:pet_key)).to eq(["bell-moth"])
  end

  it "levels a pet for NV" do
    board.ensure_starters!
    pet = character.character_pets.find_by!(pet_key: "armor-fang")
    expect {
      board.level_up!(pet_key: "armor-fang")
    }.to change { pet.reload.level }.by(1)
      .and change { user.currency_wallet.reload.nv_balance }.by(-80)
      .and change { CurrencyTransaction.where(reason: "pets.level_up").count }.by(1)
  end

  it "renames a pet with a custom nick" do
    board.ensure_starters!
    result = board.rename!(pet_key: "armor-fang", custom_name: "Зубастик")
    expect(result.ok).to be true
    expect(character.character_pets.find_by!(pet_key: "armor-fang").display_name).to eq("Зубастик")
  end

  it "sends an equipped pet on expedition and returns NV later" do
    board.ensure_starters!
    expect(board.start_expedition!(pet_key: "armor-fang", minutes: 5).ok).to be true
    pet = character.character_pets.find_by!(pet_key: "armor-fang")
    expect(pet.busy_status).to eq("expedition")
    character.update!(
      metadata: character.metadata.to_h.merge(
        "pet_expeditions" => {
          "armor-fang" => {"returns_at" => 1.minute.ago.iso8601, "started_at" => 10.minutes.ago.iso8601}
        }
      )
    )
    before = user.currency_wallet.reload.nv_balance
    completed = board.complete_due_expeditions!
    expect(completed.size).to eq(1)
    expect(pet.reload.busy_status).to eq("idle")
    expect(user.currency_wallet.reload.nv_balance).to be > before
    expect(CurrencyTransaction.where(reason: "pets.expedition").count).to be >= 1
  end
end

RSpec.describe Game::WorldEvents::Pulse do
  it "opens fish and chaos tournaments and announces them" do
    expect {
      described_class.new(rng: Random.new(1)).call
    }.to change(WorldLiveEvent, :count).by_at_least(2)
      .and change(GameEvent.where(event_type: :world_announcement), :count).by_at_least(2)

    expect(WorldLiveEvent.active.of_kind("tournament_fish")).to exist
    expect(WorldLiveEvent.active.of_kind("tournament_chaos")).to exist
  end

  it "opens a season fair while the season cadence window is open" do
    allow(Game::Seasons::Catalog).to receive(:active?).and_return(true)
    allow(Game::Seasons::Catalog).to receive(:current).and_return(
      "title_ru" => "Сезон",
      "title_en" => "Season",
      "starts_on" => Date.current.iso8601
    )
    allow(Game::Seasons::Catalog).to receive(:current_key).and_return("veil_ember_s1")

    described_class.new(rng: Random.new(2)).call
    expect(WorldLiveEvent.active.of_kind("season_fair")).to exist
  end
end
