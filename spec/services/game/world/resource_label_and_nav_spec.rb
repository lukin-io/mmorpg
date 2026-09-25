# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::ResourceLabel do
  it "maps atlas herb group ids and English Herb group labels to Ashen plant names" do
    expect(described_class.for_group("key" => "herbs_6", "label" => "Herb group 6")).to eq("Лунная орхидея")
    expect(described_class.for_group("key" => "herbs_2", "label" => "Группа трав 2")).to eq("Луговой клевер")
    expect(described_class.for_group("key" => "ash_herb", "label" => "Пепельная трава")).to eq("Пепельная трава")
  end

  it "drops English action chrome labels" do
    expect(described_class.for_group("key" => "look", "label" => "Look Around")).to be_nil
  end
end

RSpec.describe Game::World::InterruptAction do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Пепельный Берег", location_type: "outdoor") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  it "lets profile and inventory open even while a local action timer is active" do
    offer = instance_double(WorldActionOffer, accepted?: true)
    allow(Game::World::LocalActionState).to receive(:new).and_return(instance_double(Game::World::LocalActionState, call: offer))

    result = described_class.new(character:, return_context: "inventory").call
    expect(result.interrupted?).to be(false)
  end
end
