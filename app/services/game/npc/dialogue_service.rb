# frozen_string_literal: true

module Game
  module Npc
    # Handles NPC dialogue and interactions.
    #
    # Supports different NPC roles: quest_giver, vendor, trainer, guard, hostile.
    #
    # @example Start dialogue with an NPC
    #   service = Game::Npc::DialogueService.new(character: char, npc_template: npc)
    #   result = service.start_dialogue!
    #
    class DialogueService
      Result = Struct.new(:success, :dialogue_type, :data, :message, keyword_init: true)

      NPC_ROLES = {
        "quest_giver" => :handle_quest_giver,
        "vendor" => :handle_vendor,
        "trainer" => :handle_trainer,
        "guard" => :handle_guard,
        "innkeeper" => :handle_innkeeper,
        "banker" => :handle_banker,
        "auctioneer" => :handle_auctioneer,
        "crafter" => :handle_crafter,
        "hostile" => :handle_hostile
      }.freeze

      attr_reader :character, :npc_template, :errors

      def initialize(character:, npc_template:)
        @character = character
        @npc_template = npc_template
        @errors = []
      end

      # Start dialogue with the NPC
      def start_dialogue!
        return failure("NPC not found") unless npc_template
        return failure("Character not found") unless character

        handler = NPC_ROLES[npc_template.role] || :handle_generic
        send(handler)
      end

      # Get available options for current NPC
      def available_options
        case npc_template.role
        when "quest_giver"
          quest_options
        when "vendor"
          vendor_options
        when "trainer"
          trainer_options
        when "innkeeper"
          innkeeper_options
        when "banker"
          banker_options
        else
          generic_options
        end
      end

      # Process a dialogue choice
      def process_choice!(choice_key, params = {})
        case choice_key.to_s
        when "accept_quest"
          accept_quest(params[:quest_id])
        when "complete_quest"
          complete_quest(params[:quest_id])
        when "buy_item"
          buy_item(params[:item_id], params[:quantity])
        when "sell_item"
          sell_item(params[:item_id], params[:quantity])
        when "learn_skill"
          learn_skill(params[:skill_id])
        when "rest"
          rest_at_inn(params[:room_type])
        when "deposit"
          bank_deposit(params[:amount], params[:currency])
        when "withdraw"
          bank_withdraw(params[:amount], params[:currency])
        else
          failure("Unknown choice: #{choice_key}")
        end
      end

      private

      # Quest Giver handling
      def handle_quest_giver
        quests = available_quests
        active_quests = character_active_quests

        Result.new(
          success: true,
          dialogue_type: :quest_giver,
          data: {
            npc: npc_data,
            greeting: npc_greeting,
            available_quests: quests.map { |q| quest_data(q) },
            active_quests: active_quests.map { |qa| quest_assignment_data(qa) },
            completable_quests: completable_quests.map { |qa| quest_assignment_data(qa) }
          },
          message: npc_greeting
        )
      end

      def available_quests
        Quest.joins(:quest_assignments)
          .where(quest_giver_npc_id: npc_template.id)
          .where.not(quest_assignments: {character_id: character.id})
          .or(
            Quest.where(quest_giver_npc_id: npc_template.id)
              .where.not(id: character.quest_assignments.select(:quest_id))
          )
          .where("level_required <= ?", character.level)
          .distinct
          .limit(5)
      end

      def character_active_quests
        character.quest_assignments
          .includes(:quest)
          .where(quests: {quest_giver_npc_id: npc_template.id})
          .where(status: :in_progress)
      end

      def completable_quests
        character.quest_assignments
          .includes(:quest)
          .where(quests: {turn_in_npc_id: npc_template.id})
          .where(status: :in_progress)
          .select { |qa| quest_complete?(qa) }
      end

      def quest_complete?(quest_assignment)
        # Check if all objectives are completed
        quest = quest_assignment.quest
        progress = quest_assignment.progress || {}

        quest.objectives.all? do |objective|
          current = progress[objective["key"]] || 0
          current >= (objective["target"] || 1)
        end
      end

      # Vendor handling
      def handle_vendor
        Result.new(
          success: true,
          dialogue_type: :vendor,
          data: {
            npc: npc_data,
            greeting: npc_greeting,
            shop_inventory: vendor_inventory,
            player_gold: character.gold,
            buyback: [] # Could implement buyback system
          },
          message: npc_greeting
        )
      end

      def vendor_inventory
        return [] unless npc_template.metadata&.dig("inventory")

        npc_template.metadata["inventory"].map do |item_data|
          item = ItemTemplate.find_by(item_key: item_data["item_key"])
          next unless item

          {
            id: item.id,
            item_key: item.item_key,
            name: item.name,
            price: item_data["price"] || item.base_price,
            stock: item_data["stock"] || -1, # -1 = unlimited
            description: item.description,
            rarity: item.rarity
          }
        end.compact
      end

      # Trainer handling
      def handle_trainer
        Result.new(
          success: true,
          dialogue_type: :trainer,
          data: {
            npc: npc_data,
            greeting: npc_greeting,
            available_skills: trainable_skills,
            learned_skills: character.skill_nodes.pluck(:id),
            player_gold: character.gold,
            skill_points: character.skill_points_available
          },
          message: npc_greeting
        )
      end

      def trainable_skills
        return [] unless npc_template.metadata&.dig("teaches")

        trainer_class = npc_template.metadata["teaches"]["class"]
        return [] unless trainer_class

        SkillTree.where(character_class_id: trainer_class)
          .flat_map(&:skill_nodes)
          .select { |node| can_learn_skill?(node) }
          .map { |node| skill_node_data(node) }
      end

      def can_learn_skill?(skill_node)
        return false if character.skill_nodes.include?(skill_node)

        # Check requirements
        requirements = skill_node.requirements || {}

        # Level requirement
        if requirements["level"]
          return false if character.level < requirements["level"]
        end

        # Prerequisite skills
        if requirements["prerequisite_skills"]
          prereqs = requirements["prerequisite_skills"]
          return false unless prereqs.all? { |key| character.skill_nodes.exists?(key: key) }
        end

        true
      end

      # Innkeeper handling
      def handle_innkeeper
        Result.new(
          success: true,
          dialogue_type: :innkeeper,
          data: {
            npc: npc_data,
            greeting: npc_greeting,
            room_options: inn_rooms,
            player_gold: character.gold,
            current_hp: character.current_hp,
            max_hp: character.max_hp
          },
          message: npc_greeting
        )
      end

      def inn_rooms
        [
          {key: "common", name: "Common Room", price: 10, heal_percent: 50},
          {key: "private", name: "Private Room", price: 50, heal_percent: 100},
          {key: "suite", name: "Luxury Suite", price: 200, heal_percent: 100, bonus_duration: 3600}
        ]
      end

      # Banker handling
      def handle_banker
        Result.new(
          success: true,
          dialogue_type: :banker,
          data: {
            npc: npc_data,
            greeting: npc_greeting,
            bank_gold: character.user.bank_gold || 0,
            bank_silver: character.user.bank_silver || 0,
            wallet_gold: character.gold,
            wallet_silver: character.silver || 0
          },
          message: npc_greeting
        )
      end

      # Guard handling
      def handle_guard
        Result.new(
          success: true,
          dialogue_type: :guard,
          data: {
            npc: npc_data,
            greeting: guard_greeting,
            zone_info: zone_info,
            directions: nearby_locations
          },
          message: guard_greeting
        )
      end

      def guard_greeting
        faction = npc_template.faction
        if character.faction_alignment == faction || faction.nil?
          "Hail, traveler! How may I assist you?"
        else
          "Keep your business brief, #{character.faction_alignment}."
        end
      end

      def zone_info
        zone = character.current_position&.zone
        return {} unless zone

        {
          name: zone.name,
          level_range: "#{zone.level_min}-#{zone.level_max}",
          faction: zone.faction,
          pvp_enabled: zone.pvp_enabled
        }
      end

      def nearby_locations
        zone = character.current_position&.zone
        return [] unless zone

        # Return nearby zones or points of interest
        zone.metadata&.dig("landmarks") || []
      end

      # Auctioneer handling
      def handle_auctioneer
        Result.new(
          success: true,
          dialogue_type: :auctioneer,
          data: {
            npc: npc_data,
            greeting: npc_greeting,
            redirect_to: "/auction_listings"
          },
          message: "Welcome to the Auction House! Browse our listings or create your own."
        )
      end

      # Crafter handling
      def handle_crafter
        Result.new(
          success: true,
          dialogue_type: :crafter,
          data: {
            npc: npc_data,
            greeting: npc_greeting,
            redirect_to: "/crafting_jobs"
          },
          message: "Looking to craft something? Let me help you with that."
        )
      end

      # Hostile handling
      def handle_hostile
        Result.new(
          success: true,
          dialogue_type: :hostile,
          data: {
            npc: npc_data,
            can_attack: true,
            threat_level: npc_template.level <=> character.level
          },
          message: "#{npc_template.name} looks at you menacingly!"
        )
      end

      # Generic NPC handling
      def handle_generic
        Result.new(
          success: true,
          dialogue_type: :generic,
          data: {
            npc: npc_data,
            greeting: npc_greeting
          },
          message: npc_greeting
        )
      end

      # Action handlers
      def accept_quest(quest_id)
        quest = Quest.find_by(id: quest_id)
        return failure("Quest not found") unless quest

        assignment = character.quest_assignments.create!(
          quest: quest,
          status: :in_progress,
          progress: {},
          started_at: Time.current
        )

        Result.new(
          success: true,
          dialogue_type: :quest_accepted,
          data: {quest: quest_data(quest), assignment: quest_assignment_data(assignment)},
          message: "Quest accepted: #{quest.name}"
        )
      rescue ActiveRecord::RecordInvalid => e
        failure("Could not accept quest: #{e.message}")
      end

      def complete_quest(quest_id)
        assignment = character.quest_assignments.find_by(quest_id: quest_id, status: :in_progress)
        return failure("Quest not found") unless assignment
        return failure("Quest not complete") unless quest_complete?(assignment)

        quest = assignment.quest
        rewards = quest.rewards || {}

        # Grant rewards
        character.experience += rewards["xp"].to_i
        character.gold += rewards["gold"].to_i
        character.save!

        assignment.update!(status: :completed, completed_at: Time.current)

        Result.new(
          success: true,
          dialogue_type: :quest_completed,
          data: {quest: quest_data(quest), rewards: rewards},
          message: "Quest completed: #{quest.name}! You received #{rewards["xp"]} XP and #{rewards["gold"]} gold."
        )
      end

      def buy_item(item_id, quantity = 1)
        item = ItemTemplate.find_by(id: item_id)
        return failure("Item not found") unless item

        price = find_vendor_price(item) * quantity
        return failure("Not enough gold") if character.gold < price

        character.gold -= price
        character.save!

        # Add to inventory
        Game::Inventory::Manager.add_item(character, item, quantity)

        Result.new(
          success: true,
          dialogue_type: :purchase_complete,
          data: {item: item.name, quantity: quantity, total_price: price},
          message: "Purchased #{quantity}x #{item.name} for #{price} gold."
        )
      end

      def find_vendor_price(item)
        vendor_data = npc_template.metadata&.dig("inventory")&.find { |i| i["item_key"] == item.item_key }
        vendor_data&.dig("price") || item.base_price || 10
      end

      def sell_item(item_id, quantity = 1)
        inv_item = character.inventory.inventory_items.find_by(id: item_id)
        return failure("Item not found in inventory") unless inv_item
        return failure("Not enough quantity") if inv_item.quantity < quantity

        sell_price = (inv_item.item_template.base_price || 10) * quantity / 2 # 50% sell value

        if inv_item.quantity == quantity
          inv_item.destroy
        else
          inv_item.update!(quantity: inv_item.quantity - quantity)
        end

        character.gold += sell_price
        character.save!

        Result.new(
          success: true,
          dialogue_type: :sale_complete,
          data: {item: inv_item.item_template.name, quantity: quantity, gold_received: sell_price},
          message: "Sold #{quantity}x #{inv_item.item_template.name} for #{sell_price} gold."
        )
      end

      def learn_skill(skill_id)
        skill_node = SkillNode.find_by(id: skill_id)
        return failure("Skill not found") unless skill_node
        return failure("Cannot learn this skill") unless can_learn_skill?(skill_node)

        cost = skill_node.resource_cost&.dig("gold") || 100
        return failure("Not enough gold") if character.gold < cost

        character.gold -= cost
        character.character_skills.create!(skill_node: skill_node, unlocked_at: Time.current)
        character.save!

        Result.new(
          success: true,
          dialogue_type: :skill_learned,
          data: {skill: skill_node_data(skill_node)},
          message: "Learned #{skill_node.name}!"
        )
      end

      def rest_at_inn(room_type)
        room = inn_rooms.find { |r| r[:key] == room_type }
        return failure("Invalid room type") unless room
        return failure("Not enough gold") if character.gold < room[:price]

        heal_amount = (character.max_hp * room[:heal_percent] / 100.0).to_i
        character.gold -= room[:price]
        character.current_hp = [character.current_hp + heal_amount, character.max_hp].min
        character.save!

        Result.new(
          success: true,
          dialogue_type: :rested,
          data: {room: room[:name], healed: heal_amount},
          message: "You rest in the #{room[:name]} and recover #{heal_amount} HP."
        )
      end

      def bank_deposit(amount, currency = "gold")
        amount = amount.to_i
        wallet_field = currency == "gold" ? :gold : :silver
        bank_field = currency == "gold" ? :bank_gold : :bank_silver

        return failure("Invalid amount") if amount <= 0
        return failure("Not enough #{currency}") if character.send(wallet_field).to_i < amount

        character.decrement!(wallet_field, amount)
        character.user.increment!(bank_field, amount)

        Result.new(
          success: true,
          dialogue_type: :deposited,
          data: {amount: amount, currency: currency},
          message: "Deposited #{amount} #{currency} into your bank."
        )
      end

      def bank_withdraw(amount, currency = "gold")
        amount = amount.to_i
        wallet_field = currency == "gold" ? :gold : :silver
        bank_field = currency == "gold" ? :bank_gold : :bank_silver

        return failure("Invalid amount") if amount <= 0
        return failure("Not enough #{currency} in bank") if character.user.send(bank_field).to_i < amount

        character.user.decrement!(bank_field, amount)
        character.increment!(wallet_field, amount)

        Result.new(
          success: true,
          dialogue_type: :withdrawn,
          data: {amount: amount, currency: currency},
          message: "Withdrew #{amount} #{currency} from your bank."
        )
      end

      # Data formatters
      def npc_data
        {
          id: npc_template.id,
          name: npc_template.name,
          role: npc_template.role,
          level: npc_template.level,
          faction: npc_template.faction,
          description: npc_template.description
        }
      end

      def npc_greeting
        greetings = npc_template.metadata&.dig("greetings") || []
        greetings.sample || "Greetings, traveler."
      end

      def quest_data(quest)
        {
          id: quest.id,
          name: quest.name,
          description: quest.description,
          level_required: quest.level_required,
          objectives: quest.objectives,
          rewards: quest.rewards
        }
      end

      def quest_assignment_data(quest_assignment)
        {
          id: quest_assignment.id,
          quest: quest_data(quest_assignment.quest),
          status: quest_assignment.status,
          progress: quest_assignment.progress,
          completable: quest_complete?(quest_assignment)
        }
      end

      def skill_node_data(node)
        {
          id: node.id,
          key: node.key,
          name: node.name,
          type: node.node_type,
          tier: node.tier,
          effects: node.effects,
          cost: node.resource_cost&.dig("gold") || 100,
          requirements: node.requirements
        }
      end

      def quest_options
        [
          {key: "view_quests", label: "What quests do you have?"},
          {key: "turn_in", label: "I've completed a quest."},
          {key: "goodbye", label: "Goodbye."}
        ]
      end

      def vendor_options
        [
          {key: "buy", label: "Let me see your wares."},
          {key: "sell", label: "I have items to sell."},
          {key: "goodbye", label: "Goodbye."}
        ]
      end

      def trainer_options
        [
          {key: "train", label: "I want to learn new skills."},
          {key: "reset", label: "I want to reset my skills."},
          {key: "goodbye", label: "Goodbye."}
        ]
      end

      def innkeeper_options
        [
          {key: "rest", label: "I need a room."},
          {key: "rumors", label: "Heard any rumors?"},
          {key: "goodbye", label: "Goodbye."}
        ]
      end

      def generic_options
        [
          {key: "talk", label: "Tell me about yourself."},
          {key: "goodbye", label: "Goodbye."}
        ]
      end

      def failure(message)
        @errors << message
        Result.new(success: false, dialogue_type: :error, data: {}, message: message)
      end
    end
  end
end
