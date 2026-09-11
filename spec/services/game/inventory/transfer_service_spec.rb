# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Inventory::TransferService do
  let(:character) { create(:character) }
  let(:recipient) { create(:character) }
  let(:template) { create(:item_template, durability_max: 30, stack_limit: 1) }
  let(:item) do
    create(:inventory_item, inventory: character.inventory, item_template: template,
      properties: {"current_durability" => 12})
  end
  let(:service) { described_class.new(character:) }

  it "copies current acquired durability after a catalog correction even when the caller loaded an older item" do
    stale = InventoryItem.find(item.id)
    item.update!(properties: {"max_durability" => 30, "current_durability" => 11, "bound_note" => "retained"})
    template.update!(durability_max: 20)

    result = service.transfer_item!(item: stale, recipient_name: recipient.name)

    expect(result).to have_attributes(success: true)
    received = recipient.inventory.inventory_items.find_by!(item_template: template)
    expect(received).to have_attributes(current_durability: 11, max_durability: 30)
    expect(received.properties).to include("bound_note" => "retained")
    expect(character.inventory.inventory_items.where(id: item.id)).not_to exist
  end

  it "revalidates the locked source before transferring a stale caller's item" do
    stale = InventoryItem.find(item.id)
    item.update!(equipped: true, equipment_slot: "main_hand")

    result = service.transfer_item!(item: stale, recipient_name: recipient.name)

    expect(result).to have_attributes(success: false, message: "Equipped items cannot be transferred.")
    expect(item.reload.inventory).to eq(character.inventory)
    expect(recipient.inventory.inventory_items).to be_empty
  end

  it "rejects a repeated transfer after the source row has been removed" do
    stale = InventoryItem.find(item.id)
    expect(service.transfer_item!(item:, recipient_name: recipient.name)).to have_attributes(success: true)

    result = service.transfer_item!(item: stale, recipient_name: recipient.name)

    expect(result).to have_attributes(success: false, message: "Item not found.")
    expect(recipient.inventory.inventory_items.where(item_template: template).count).to eq(1)
  end

  it "rejects a recipient with no free slot without removing the source or changing either carried mass" do
    source = item
    character.inventory.update!(current_weight: source.weight)
    recipient.inventory.update!(slot_capacity: 1, current_weight: 1)
    create(:inventory_item, inventory: recipient.inventory, weight: 1)

    result = service.transfer_item!(item: source, recipient_name: recipient.name, gift: true)

    expect(result).to have_attributes(success: false, message: "Recipient has no free inventory slots.")
    expect(source.reload.inventory_id).to eq(character.inventory.id)
    expect(character.inventory.reload.current_weight).to eq(source.weight)
    expect(recipient.inventory.reload.current_weight).to eq(1)
    expect(recipient.inventory.inventory_items.count).to eq(1)
  end

  context "concurrent inventory arrivals", js: true do
    def database_thread(results, &operation)
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          results << operation.call
        rescue => error
          results << error
        end
      end
    end

    def join_workers(workers)
      workers.each { |worker| expect(worker.join(10)).to eq(worker) }
    end

    def stop_workers(workers)
      workers.compact.each do |worker|
        worker.kill if worker.alive?
        worker.join
      end
    end

    it "serializes an incoming gift with a Shop purchase competing for the last carried mass" do
      source = item
      character.inventory.update!(current_weight: source.weight)
      target_inventory = recipient.inventory
      available_weight = target_inventory.max_weight - source.weight
      create(:inventory_item, inventory: target_inventory, weight: available_weight)
      target_inventory.update!(current_weight: available_weight)
      city = create(:zone, location_type: "city")
      create(:character_position, character: recipient, zone: city, x: 5, y: 5)
      hotspot = create(:city_hotspot, :shop, zone: city, required_level: 1)
      account = ShopAccount.create!(location: hotspot, nv_balance: 1_000)
      purchase_template = create(:item_template, key: "capacity_race_knife", base_price: 7,
        weight: source.weight, stack_limit: 1, durability_max: 10,
        enhancement_rules: {"subcategory" => "knives", "shop" => {"sold" => true}})
      stock = account.shop_stocks.create!(item_template: purchase_template, current: 5, maximum: 10)
      recipient.remember_gameplay_context!(name: "shop")
      wallet = recipient.user.currency_wallet
      wallet.update!(nv_balance: 100)
      offer = Game::Shop::TradeOffers.new(character: recipient)
        .issue(buy_items: [purchase_template]).fetch(:buy).fetch(purchase_template.id)

      ready = Queue.new
      release = Queue.new
      purchase_pid = Queue.new
      gift_results = Queue.new
      purchase_results = Queue.new
      allow_any_instance_of(described_class).to receive(:find_destination_stack).and_wrap_original do |original, *args|
        destination = original.call(*args)
        if Thread.current[:pause_incoming_gift]
          # Pause after the gift's capacity read, before either inventory changes.
          ready << true
          release.pop
        end
        destination
      end

      gift_worker = database_thread(gift_results) do
        Thread.current[:pause_incoming_gift] = true
        described_class.new(character: Character.find(character.id))
          .transfer_item!(item: InventoryItem.find(source.id), recipient_name: recipient.name, gift: true)
      ensure
        Thread.current[:pause_incoming_gift] = nil
      end
      Timeout.timeout(5) { ready.pop }
      purchase_worker = database_thread(purchase_results) do
        purchase_pid << ActiveRecord::Base.connection.select_value("SELECT pg_backend_pid()")
        Game::Shop::Purchase.new(character: Character.find(recipient.id),
          item_template: ItemTemplate.find(purchase_template.id), action_key: offer.action_key).call
      end
      pid = Timeout.timeout(5) { purchase_pid.pop }
      Timeout.timeout(5) do
        loop do
          break unless purchase_results.empty?
          break if ActiveRecord::Base.connection.select_value("SELECT cardinality(pg_blocking_pids(#{Integer(pid)}))").positive?

          sleep 0.01
        end
      end
      release << true
      join_workers([gift_worker, purchase_worker])

      expect(gift_results.pop).to have_attributes(success: true)
      expect(purchase_results.pop).to have_attributes(success: false, message: "Inventory is overloaded")
      expect(target_inventory.reload.current_weight).to eq(target_inventory.max_weight)
      expect(target_inventory.inventory_items.sum("weight * quantity")).to eq(target_inventory.current_weight)
      expect(target_inventory.inventory_items.where(item_template: template).count).to eq(1)
      expect(target_inventory.inventory_items.where(item_template: purchase_template)).not_to exist
      expect(character.inventory.reload.current_weight).to eq(0)
      expect(InventoryItem.exists?(source.id)).to be(false)
      expect(wallet.reload.nv_balance).to eq(100)
      expect(wallet.currency_transactions).to be_empty
      expect(account.reload.nv_balance).to eq(1_000)
      expect(stock.reload.current).to eq(5)
      expect(offer.reload).to be_offered
    ensure
      release << true if release
      stop_workers([gift_worker, purchase_worker])
    end

    it "completes opposite-direction transfers of different templates without losing either inventory weight" do
      source = item
      other_template = create(:item_template, stack_limit: 1, weight: 3)
      other_item = create(:inventory_item, inventory: recipient.inventory, item_template: other_template)
      character.inventory.update!(current_weight: source.weight)
      recipient.inventory.update!(current_weight: other_item.weight)
      requests = [[character.id, source.id, recipient.name], [recipient.id, other_item.id, character.name]]
      gate = Queue.new
      results = Queue.new
      workers = requests.map do |sender_id, item_id, recipient_name|
        database_thread(results) do
          gate.pop
          described_class.new(character: Character.find(sender_id))
            .transfer_item!(item: InventoryItem.find(item_id), recipient_name:)
        end
      end
      requests.size.times { gate << true }
      join_workers(workers)

      expect(requests.size.times.map { results.pop }).to all(have_attributes(success: true))
      expect(character.inventory.reload.current_weight).to eq(other_item.weight)
      expect(recipient.inventory.reload.current_weight).to eq(source.weight)
      expect(character.inventory.inventory_items.sole.item_template).to eq(other_template)
      expect(recipient.inventory.inventory_items.sole.item_template).to eq(template)
      expect(InventoryItem.where(item_template: [template, other_template]).sum(:quantity)).to eq(2)
    ensure
      stop_workers(workers || [])
    end
  end
end
