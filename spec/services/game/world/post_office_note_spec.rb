# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PostOfficeNote do
  let(:character) { create(:character) }

  it "stores and clears a personal note" do
    save = described_class.new(character:, body: "Встреча у ворот").save!
    expect(save.success).to be(true)
    expect(described_class.current_for(character.reload)).to eq("Встреча у ворот")

    clear = described_class.new(character:).clear!
    expect(clear.success).to be(true)
    expect(described_class.current_for(character.reload)).to eq("")
  end

  it "rejects blank notes" do
    expect(described_class.new(character:, body: "   ").save!.success).to be(false)
  end
end
