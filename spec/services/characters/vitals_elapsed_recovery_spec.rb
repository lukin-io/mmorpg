# frozen_string_literal: true

require "rails_helper"
RSpec.describe Characters::VitalsService, "elapsed recovery" do
  it "preserves fractional mana, handles retries and uses effective skills" do
    character = create(:character, max_hp: 600, current_hp: 0, max_mp: 7, current_mp: 0, last_regen_tick_at: Time.current)
    origin = Time.current
    service = described_class.new(character, clock: -> { origin + 150.seconds })
    service.tick_regeneration
    expect(character.reload.current_hp).to eq(150)
    expect(character.current_mp).to eq(1)
    service.tick_regeneration
    expect(character.reload.current_hp).to eq(150)
    character.update!(passive_skills: {"self_healing" => 100})
    described_class.new(character, clock: -> { origin + 200.seconds }).tick_regeneration
    expect(character.reload.current_hp).to eq(250)
  end

  it "never revives a participant in an active fight" do
    character = create(:character, current_hp: 0, last_regen_tick_at: 1.hour.ago)
    create(:arena_participation, character:, arena_match: create(:arena_match, :live))
    expect(described_class.new(character).tick_regeneration).to be false
    expect(character.reload.current_hp).to eq(0)
  end
end
