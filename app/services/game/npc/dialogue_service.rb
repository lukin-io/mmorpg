# frozen_string_literal: true

module Game
  module Npc
    # Handles NPC dialogue and interactions.
    #
    # Supports different NPC roles: vendor, trainer, guard, hostile, and local
    # service NPCs.
    #
    # @example Start dialogue with an NPC
    #   service = Game::Npc::DialogueService.new(character: char, npc_template: npc)
    #   result = service.start_dialogue!
    #
    class DialogueService
      Result = Struct.new(:success, :dialogue_type, :data, :message, keyword_init: true)

      NPC_ROLES = {
        "vendor" => :handle_vendor,
        "trainer" => :handle_trainer,
        "guard" => :handle_guard,
        "innkeeper" => :handle_innkeeper,
        "banker" => :handle_banker,
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
        when "buy_item"
          buy_item(params[:item_id], params[:quantity])
        when "sell_item"
          sell_item(params[:item_id], params[:quantity])
        when "learn_skill"
          failure("Skill training is handled from the character skills page")
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
            available_skills: [],
            learned_skills: character.passive_skills.keys,
            player_gold: character.gold,
            skill_points: character.skill_points_available
          },
          message: npc_greeting
        )
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
        zone = character.position&.zone
        return {} unless zone

        level_min = zone.metadata&.dig("level_min")
        level_max = zone.metadata&.dig("level_max")
        level_range =
          if level_min.present? && level_max.present?
            "#{level_min}-#{level_max}"
          else
            "Unknown"
          end

        {
          name: zone.name,
          level_range: level_range,
          faction: zone.metadata&.dig("faction")
        }
      end

      def nearby_locations
        zone = character.position&.zone
        return [] unless zone

        # Return nearby zones or points of interest
        zone.metadata&.dig("landmarks") || []
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
        wallet_field = (currency == "gold") ? :gold : :silver
        bank_field = (currency == "gold") ? :bank_gold : :bank_silver

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
        wallet_field = (currency == "gold") ? :gold : :silver
        bank_field = (currency == "gold") ? :bank_gold : :bank_silver

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
