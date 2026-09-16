# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Inventory::AttackScroll do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone) }
  let(:attacker) { create(:character, level: 17, passive_skills: {"stealth" => 20}) }
  let(:target) { create(:character, level: 17) }
  let(:inventory) { create(:inventory, character: attacker, current_weight: 2) }
  let(:template) do
    create(:item_template, key: "duel_permit_i", item_type: "consumable", slot: "none", weight: 1,
      durability_max: 1, requirements: {"level" => 5, "stealth" => 20})
  end
  let(:item) { create(:inventory_item, inventory:, item_template: template, quantity: 2, weight: 1) }
  let(:service) { described_class.new(character: attacker) }
  let(:offer) { service.offer_for(item:) }

  before do
    create(:character_position, character: attacker, zone:)
    create(:character_position, character: target, zone:)
    create(:user_session, user: target.user, last_seen_at: Time.current)
  end

  def use_scroll(name = target.name)
    service.call(action_key: offer.action_key, target_name: name)
  end

  def expect_rejection(message)
    offer
    state = [item.reload.attributes, inventory.reload.current_weight, ArenaMatch.count, GameEvent.count]
    expect { use_scroll }.to raise_error(described_class::Unavailable, message)
    expect([item.reload.attributes, inventory.reload.current_weight, ArenaMatch.count, GameEvent.count]).to eq(state)
    expect(offer.reload).to be_offered
  end

  it "opens and reuses a form without consuming anything" do
    expect(service.offer_for(item:).id).to eq(offer.id)
    expect(item.reload.quantity).to eq(2)
    expect(ArenaMatch.count).to eq(0)
  end

  it "creates the shared physical match and spends exactly one use, including retries after completion" do
    match = use_scroll(" #{target.name.upcase} ")
    expect(match).to be_live
    expect(match.metadata).to include("source" => "scroll_pvp", "physical_only" => true, "fight_timeout_seconds" => 300)
    expect(match.trauma_percent).to eq(10)
    expect(match.arena_participations.pluck(:character_id, :team)).to contain_exactly([attacker.id, "a"], [target.id, "b"])
    expect(match.arena_participations.map { |p| p.metadata.dig("combat_profile", "max_magic_mana") }).to eq([0, 0])
    expect(item.reload.quantity).to eq(1)
    expect(item.current_durability).to eq(1)
    expect(inventory.reload.current_weight).to eq(1)
    expect(GameEvent.count).to eq(2)
    expect(use_scroll.id).to eq(match.id)
    Arena::CombatProcessor.new(match).end_match(nil)
    expect(use_scroll.id).to eq(match.id)
    expect(ArenaMatch.count).to eq(1)
    expect(item.reload.quantity).to eq(1)
  end

  [14, 20].each do |level|
    it "accepts the exact #{level} target level boundary" do
      target.update!(level:)
      expect(use_scroll).to be_live
    end
  end

  it "admits the observed low-HP armed attacker without Arena's half-health gate or gear removal" do
    attacker.update!(current_hp: 285, max_hp: 1375)
    target.update!(level: 19, current_hp: 300, max_hp: 300)
    gear = create(:inventory_item, inventory:, equipped: true, equipment_slot: "main_hand")
    travel_to(Time.current) do
      match = use_scroll

      expect(match).to be_live
      expect(match.arena_applications).to be_empty
      expect(attacker.reload.current_hp).to eq(285)
      expect(gear.reload).to be_equipped
      expect(item.reload.quantity).to eq(1)
      expect(match.combat_log_entries.first.message).to include("#{attacker.name}[17] and #{target.name}[19] started (attack)")
    end
  end

  [13, 21].each do |level|
    it "preserves the scroll outside the level window at #{level}" do
      target.update!(level:)
      expect_rejection("Error using item. Scroll use failed.")
    end
  end

  %w[duel_permit_i fist_attack].each do |scroll_key|
    it "preserves scrolls, both players' gear and vitals on the observed 17 -> 5 #{scroll_key} rejection" do
      template.update!(key: scroll_key, requirements: {"level" => scroll_key == "fist_attack" ? 10 : 5})
      target.update!(level: 5)
      inventory
      gear = create(:item_template, item_type: "equipment", slot: "main_hand", stat_modifiers: {"hp" => 50})
      equipped = [attacker, target].map do |player|
        create(:inventory_item, inventory: player.inventory || create(:inventory, character: player),
          item_template: gear, equipped: true, equipment_slot: "main_hand")
      end
      vitals = [attacker, target].map { |player| [player.current_hp, player.current_mp] }

      2.times { expect_rejection("Error using item. Scroll use failed.") }

      expect(equipped.map(&:reload)).to all(have_attributes(equipped: true, equipment_slot: "main_hand"))
      expect([attacker, target].map { |player| [player.reload.current_hp, player.current_mp] }).to eq(vitals)
      expect([attacker, target]).to all(have_attributes(in_combat: false))
    end
  end

  it "rechecks Stealth after the form opens" do
    offer
    attacker.update!(passive_skills: {"stealth" => 19})
    expect_rejection(/Stealth 20/)
  end

  it "rejects self-targeting" do
    expect { use_scroll(attacker.name) }.to raise_error(described_class::Unavailable, /yourself/)
    expect(item.reload.quantity).to eq(2)
  end

  it "rejects offline targets" do
    target.user.user_sessions.update_all(signed_out_at: Time.current)
    expect_rejection(/offline/)
  end

  it "does not treat a non-playable character as online through its owner's session" do
    create(:character, user: target.user, created_at: 1.day.ago)
    expect_rejection(/offline/)
  end

  it "rejects a target who has left the cell" do
    target.position.update!(x: 1)
    expect_rejection(/same location/)
  end

  it "rejects a moving target without consuming a charge" do
    create(:movement_command, :moving, character: target, zone:)
    expect_rejection(/Finish moving/)
  end

  it "rechecks the attacker's HP after opening Use" do
    offer
    attacker.update!(current_hp: 0)
    expect { use_scroll }.to raise_error(described_class::Unavailable, /recover/)
    expect(item.reload.quantity).to eq(2)
    expect(ArenaMatch.count).to eq(0)
  end

  it "rejects a caller who leaves after opening the form" do
    offer
    attacker.position.update!(x: 1)
    target.position.update!(x: 1)
    expect_rejection(/Reopen/)
  end

  it "rejects expiry at the exact deadline" do
    offer.update!(expires_at: Time.current)
    expect_rejection(/Reopen/)
  end

  it "rejects a broken scroll without consuming it" do
    offer
    item.update!(properties: {"current_durability" => 0})
    expect_rejection(/broken/)
  end

  it "rejects a transferred or missing item" do
    offer
    item.update!(inventory: create(:inventory, character: target))
    expect { use_scroll }.to raise_error(described_class::Unavailable, /unavailable/)
    expect(ArenaMatch.count).to eq(0)
  end

  it "rejects a foreign capability" do
    expect { described_class.new(character: target).call(action_key: offer.action_key, target_name: attacker.name) }
      .to raise_error(described_class::Unavailable, /Reopen/)
    expect(item.reload.quantity).to eq(2)
  end

  it "serializes simultaneous retries of the same use", js: true do
    key = offer.action_key
    attacker_id, target_name = attacker.id, target.name
    gate = Queue.new
    workers = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          described_class.new(character: Character.find(attacker_id)).call(action_key: key, target_name:).id
        end
      end
    end
    2.times { gate << true }
    expect(workers.map(&:value).uniq.size).to eq(1)
    expect(ArenaMatch.count).to eq(1)
    expect(item.reload.quantity).to eq(1)
    expect(GameEvent.count).to eq(2)
  end

  it "does not put a target into two fights when attackers race", js: true do
    second = create(:character, level: 17, passive_skills: {"stealth" => 20})
    create(:character_position, character: second, zone:)
    second_item = create(:inventory_item, inventory: create(:inventory, character: second, current_weight: 1),
      item_template: template, quantity: 1, weight: 1)
    entries = [[attacker.id, offer.action_key], [second.id, described_class.new(character: second).offer_for(item: second_item).action_key]]
    name = target.name
    gate = Queue.new
    workers = entries.map do |id, key|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          described_class.new(character: Character.find(id)).call(action_key: key, target_name: name).id
        rescue described_class::Unavailable
          nil
        end
      end
    end
    2.times { gate << true }
    expect(workers.map(&:value).compact.uniq.size).to eq(1)
    expect(target.arena_participations.joins(:arena_match).merge(ArenaMatch.active).count).to eq(1)
    expect(ArenaMatch.count).to eq(1)
  end

  it "rolls back the match, equipment and scroll if the durable event fails" do
    allow_any_instance_of(Chat::EventPublisher).to receive(:system_information!).and_raise("storage unavailable")
    expect { use_scroll }.to raise_error("storage unavailable")
    expect(ArenaMatch.count).to eq(0)
    expect(attacker.reload).not_to be_in_combat
    expect(target.reload).not_to be_in_combat
    expect(item.reload.quantity).to eq(2)
    expect(offer.reload).to be_offered
  end

  context "Fist Attack" do
    before do
      template.update!(key: "fist_attack", requirements: {"level" => 10})
      attacker.update!(passive_skills: {})
    end

    it "requires no Stealth, removes all equipment on both players and clamps HP without refilling" do
      attacker.update!(metadata: {"artifact_grade" => "large", "combat_profile" => {"block_table" => "shield", "physical_attack_cost_seed" => 1}})
      gear = create(:item_template, item_type: "equipment", slot: "main_hand", stat_modifiers: {"hp" => 50, "strength" => 10})
      first = create(:inventory_item, inventory:, item_template: gear, equipped: true, equipment_slot: "main_hand")
      second = create(:inventory_item, inventory: create(:inventory, character: target), item_template: gear,
        equipped: true, equipment_slot: "main_hand")
      match = use_scroll
      expect(match.metadata["fight_kind"]).to eq("no_weapons")
      expect(match.trauma_percent).to eq(80)
      expect([first.reload, second.reload]).to all(have_attributes(equipped: false, equipment_slot: nil))
      expect(attacker.reload.current_hp).to be <= attacker.effective_max_hp
      expect(target.reload.current_hp).to be <= target.effective_max_hp
      participation = match.arena_participations.find_by!(character: attacker)
      expect(participation.metadata.dig("combat_profile", "block_table")).to eq("normal")
      expect(participation.metadata.dig("combat_profile", "physical_attack_cost_seed")).to be > 1
      expect(Arena::CombatAttributes.for(participation)[:damage_multiplier]).to eq(1.0)
    end

    it "still requires level 10" do
      attacker.update!(level: 9)
      expect { offer }.to raise_error(described_class::Unavailable, /Level 10/)
    end

    it "preserves the observed stripped maxima and one charge on repeated Fist entry" do
      attacker.update!(current_hp: 375, max_hp: 225)
      target.update!(current_hp: 175, max_hp: 175)
      gear = create(:item_template, item_type: "equipment", slot: "main_hand", stat_modifiers: {"hp" => 1150})
      equipped = create(:inventory_item, inventory:, item_template: gear, equipped: true, equipment_slot: "main_hand")

      match = use_scroll
      expect(attacker.reload).to have_attributes(current_hp: 225, max_hp: 225)
      expect(target.reload).to have_attributes(current_hp: 175, max_hp: 175)
      expect(equipped.reload).not_to be_equipped
      expect(match.combat_log_entries.first.message).to include("started (fist attack)")
      expect(use_scroll.id).to eq(match.id)
      expect(item.reload.quantity).to eq(1)
      expect(match.combat_log_entries.where("message LIKE ?", "%started (fist attack)%").count).to eq(1)
    end
  end

  context "intervening against a living player" do
    let(:opponent) { create(:character, level: 17) }
    let(:match) { create(:arena_match, :live, zone:, trauma_percent: 30, metadata: {"physical_only" => true, "fight_kind" => "free"}) }
    let!(:defender) { create(:arena_participation, arena_match: match, character: target, team: "a") }
    let!(:enemy) { create(:arena_participation, arena_match: match, character: opponent, team: "b") }

    it "joins the opposite side and preserves existing turns, deadline and trauma" do
      defender.update!(metadata: {"pending_turn" => {"round_number" => match.current_turn_number, "attacks" => []}})
      started = match.started_at
      expect(use_scroll.id).to eq(match.id)
      expect(match.reload).to be_team_battle
      expect(match.started_at).to eq(started)
      expect(match.trauma_percent).to eq(30)
      expect(defender.reload.metadata["pending_turn"]).to be_present
      entrant = match.arena_participations.find_by!(character: attacker)
      expect(entrant.team).to eq("b")
      expect(entrant.metadata["current_ap"]).to be_positive
    end

    it "rejects a defeated player even after their character recovered HP" do
      defender.update!(result: :defeat)
      expect_rejection(/Defeated/)
    end

    it "rejects closed fights" do
      match.update!(metadata: match.metadata.merge("fight_kind" => "closed"))
      expect_rejection(/intervention/)
    end

    it "rejects Fist intervention without stripping gear or spending a charge" do
      template.update!(key: "fist_attack", requirements: {"level" => 10})
      gear = create(:inventory_item, inventory:, equipped: true, equipment_slot: "main_hand")
      expect_rejection(/outside combat/)
      expect(gear.reload).to be_equipped
    end

    it "joins the NPC side of the same wilderness fight without replacing its roster" do
      npc = create(:npc_template)
      enemy.update!(character: nil, user: nil, npc_template: npc)
      match.update!(metadata: match.metadata.merge("source" => "wilderness"))
      expect(use_scroll.id).to eq(match.id)
      expect(match.arena_participations.count).to eq(3)
      expect(enemy.reload.npc_template).to eq(npc)
      expect(match.arena_participations.find_by!(character: attacker).team).to eq(enemy.team)
      expect(match.arena_participations.find_by!(character: attacker).metadata["current_ap"]).to be_positive
    end

    it "rechecks the receiving fight's equipment restriction" do
      match.update!(metadata: match.metadata.merge("fight_kind" => "no_weapons"))
      create(:inventory_item, inventory:, equipped: true, equipment_slot: "main_hand")
      expect_rejection(/Remove all equipment/)
    end
  end
end
