# frozen_string_literal: true

require "rails_helper"

RSpec.describe InventoryItem, type: :model do
  let(:template) { create(:item_template, durability_max: 30) }
  let(:item) { create(:inventory_item, item_template: template, properties: {"current_durability" => 10}) }

  it "preserves a newer acquired maximum and properties when wear starts from a stale instance" do
    stale = described_class.find(item.id)
    item.update!(properties: {"max_durability" => 30, "current_durability" => 7, "bound_note" => "retained"})
    template.update!(durability_max: 20)

    expect(stale.decrement_durability!).to eq(6)

    expect(stale.reload).to have_attributes(current_durability: 6, max_durability: 30)
    expect(stale.properties).to include("bound_note" => "retained")
  end

  it "applies successive durability losses even when both callers loaded the original state" do
    stale = described_class.find(item.id)

    item.decrement_durability!
    stale.decrement_durability!

    expect(item.reload.current_durability).to eq(8)
  end

  it "serializes simultaneous stale writers without losing the acquired maximum", js: true do
    item_id = item.id
    ready = Queue.new
    release = Queue.new
    results = Queue.new
    workers = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          stale = described_class.find(item_id)
          ready << true
          release.pop
          results << stale.decrement_durability!
        rescue => error
          results << error
        end
      end
    end
    Timeout.timeout(5) { 2.times { ready.pop } }
    item.update!(properties: {"max_durability" => 30, "current_durability" => 10})
    template.update!(durability_max: 20)
    2.times { release << true }
    workers.each { |worker| expect(worker.join(5)).to eq(worker) }

    expect(2.times.map { results.pop }.sort).to eq([8, 9])
    expect(item.reload).to have_attributes(current_durability: 8, max_durability: 30)
  ensure
    2.times { release << true }
    workers&.each do |worker|
      worker.kill if worker.alive?
      worker.join
    end
  end

  it "reloads the acquired maximum and retains unrelated properties when resetting durability" do
    stale = described_class.find(item.id)
    item.update!(properties: {"max_durability" => 40, "current_durability" => 0, "bound_note" => "retained"})
    template.update!(durability_max: 20)

    stale.reset_durability!

    expect(stale.reload).to have_attributes(current_durability: 40, max_durability: 40)
    expect(stale.properties).to include("bound_note" => "retained")
  end

  it "unequips an item when its locked current durability reaches zero" do
    item.update!(equipped: true, equipment_slot: "main_hand", properties: {"current_durability" => 1})

    expect(item.decrement_durability!).to eq(0)

    expect(item.reload).to have_attributes(current_durability: 0, equipped: false, equipment_slot: nil)
  end

  it "leaves non-durable items unchanged" do
    template.update!(durability_max: 0)
    item.update!(properties: {"bound_note" => "retained"})
    original = item.attributes

    expect(item.decrement_durability!).to eq(0)
    item.reset_durability!

    expect(item.reload.attributes).to eq(original)
  end
end
