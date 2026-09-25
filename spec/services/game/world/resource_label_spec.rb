# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::ResourceLabel do
  it "maps atlas herb group ids and legacy English labels to Ashen plant names" do
    expect(described_class.for_group("key" => "herbs_6", "label" => "Herb group 6")).to eq("Лунная орхидея")
    expect(described_class.for_group("key" => "herbs_2", "label" => "Группа трав 2")).to eq("Луговой клевер")
    expect(described_class.for_group("key" => "trees_1", "label" => "Tree group 1")).to eq("Пепельная берёза")
    expect(described_class.for_group("key" => "ash_herb", "label" => "Пепельная трава")).to eq("Пепельная трава")
    expect(described_class.for_group("key" => "look", "label" => "Look Around")).to be_nil
  end
end
