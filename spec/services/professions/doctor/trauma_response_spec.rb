require "rails_helper"

RSpec.describe Professions::Doctor::TraumaResponse do
  let(:profession) { create(:profession, name: "Doctor", healing_bonus: 15) }
  let(:progress) { create(:profession_progress, profession:, skill_level: 5) }
  let(:character) { create(:character, :with_position) }
  let(:position) { character.position }

  before do
    position.update!(respawn_available_at: 5.minutes.from_now)
  end

  it "shortens respawn timers using doctor bonus" do
    described_class.new(doctor_progress: progress).apply!(character_position: position)

    expect(position.reload.respawn_available_at).to be < 5.minutes.from_now
  end
end

