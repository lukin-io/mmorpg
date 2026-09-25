# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::Journal do
  it "auto-accepts the starter shore contract once" do
    character = create(:character)
    journal = described_class.new(character:)

    first = journal.ensure_starter!
    expect(first.success).to be(true)
    expect(journal.present(Game::Quests::Catalog.find("veil_lure_drill"))[:status]).to eq("active")

    second = journal.ensure_starter!
    expect(second).to be_nil
  end
end
