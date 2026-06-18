# frozen_string_literal: true

module Game
  module Inventory
    # Handles source-backed direct item and NV transfer forms from inventory.
    class TransferService
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def transfer_item!(item:, recipient_name:, quantity: 1, gift: false)
        move_item!(
          item:,
          recipient_name:,
          quantity:,
          reason: gift ? "inventory.gift" : "inventory.transfer",
          success_message: gift ? "Gift sent." : "Item transferred."
        )
      end

      def sell_item!(item:, recipient_name:, quantity: 1, price:)
        return failure("Trade license required.") unless trade_license?

        price = decimal_value(price)
        return failure("Price must be positive.") unless price.positive?

        recipient = find_recipient(recipient_name)
        return recipient unless recipient.is_a?(Character)

        buyer_wallet = wallet_for(recipient)
        seller_wallet = wallet_for(character)
        return failure("Recipient does not have enough NV.") if buyer_wallet.nv_balance < price
        metadata = transfer_metadata(item, quantity)

        ApplicationRecord.transaction do
          transfer_stack!(item:, recipient:, quantity: quantity.to_i)
          buyer_wallet.adjust!(
            amount: -price,
            reason: "inventory.player_sale.buy",
            metadata:
          )
          seller_wallet.adjust!(
            amount: price,
            reason: "inventory.player_sale.sell",
            metadata: metadata.merge("recipient" => recipient.name)
          )
        end

        success("Item sold to #{recipient.name}.")
      rescue CapacityError, OwnershipError => e
        failure(e.message)
      rescue Economy::WalletService::InsufficientFundsError
        failure("Recipient does not have enough NV.")
      end

      def transfer_money!(recipient_name:, amount:)
        amount = decimal_value(amount)
        return failure("Amount must be positive.") unless amount.positive?

        recipient = find_recipient(recipient_name)
        return recipient unless recipient.is_a?(Character)

        sender_wallet = wallet_for(character)
        recipient_wallet = wallet_for(recipient)

        ApplicationRecord.transaction do
          sender_wallet.adjust!(
            amount: -amount,
            reason: "inventory.money_transfer.sent",
            metadata: {"recipient" => recipient.name}
          )
          recipient_wallet.adjust!(
            amount: amount,
            reason: "inventory.money_transfer.received",
            metadata: {"sender" => character.name}
          )
        end

        success("NV transferred to #{recipient.name}.")
      rescue Economy::WalletService::InsufficientFundsError
        failure("Not enough NV.")
      end

      private

      class CapacityError < StandardError; end
      class OwnershipError < StandardError; end

      attr_reader :character

      def move_item!(item:, recipient_name:, quantity:, reason:, success_message:)
        recipient = find_recipient(recipient_name)
        return recipient unless recipient.is_a?(Character)

        ApplicationRecord.transaction do
          transfer_stack!(item:, recipient:, quantity: quantity.to_i, reason:)
        end

        success(success_message)
      rescue CapacityError, OwnershipError => e
        failure(e.message)
      end

      def transfer_stack!(item:, recipient:, quantity:, reason: "inventory.transfer")
        raise OwnershipError, "Item not found." unless item&.inventory&.character_id == character.id
        raise OwnershipError, "Invalid quantity." unless quantity.positive?
        raise OwnershipError, "Not enough items in stack." if quantity > item.quantity.to_i
        raise OwnershipError, "Equipped items cannot be transferred." if item.equipped?
        raise OwnershipError, "Protected items cannot be transferred." if item.protected_from_discard?

        recipient_inventory = recipient.inventory || recipient.create_inventory!
        source_inventory = item.inventory
        delta_weight = item.weight.to_i * quantity

        raise CapacityError, "Recipient inventory is overloaded." if recipient_inventory.current_weight.to_i + delta_weight > recipient_inventory.weight_capacity.to_i

        destination_stack = find_destination_stack(recipient_inventory, item, quantity)
        needs_new_slot = destination_stack.nil?
        raise CapacityError, "Recipient has no free inventory slots." if needs_new_slot && recipient_inventory.inventory_items.count >= recipient_inventory.slot_capacity.to_i

        if destination_stack
          destination_stack.increment!(:quantity, quantity)
        else
          destination_stack = recipient_inventory.inventory_items.create!(
            item_template: item.item_template,
            quantity: quantity,
            weight: item.weight,
            properties: item.properties,
            bound: item.bound,
            slot_kind: item.slot_kind
          )
        end

        if item.quantity > quantity
          item.decrement!(:quantity, quantity)
        else
          item.destroy!
        end

        source_inventory.update!(current_weight: [source_inventory.current_weight.to_i - delta_weight, 0].max)
        recipient_inventory.increment!(:current_weight, delta_weight)

        destination_stack
      end

      def find_destination_stack(inventory, item, quantity)
        return nil if item.item_template.stack_limit.to_i <= 1

        inventory.inventory_items.where(item_template: item.item_template, equipped: false).order(:created_at).find do |candidate|
          candidate.properties.to_h == item.properties.to_h &&
            candidate.bound? == item.bound? &&
            candidate.quantity.to_i + quantity <= item.item_template.stack_limit.to_i
        end
      end

      def find_recipient(name)
        normalized = name.to_s.strip
        return failure("Recipient is required.") if normalized.blank?

        recipient = Character.where("LOWER(name) = ?", normalized.downcase).first
        return failure("Recipient not found.") unless recipient
        return failure("Cannot target yourself.") if recipient.id == character.id

        recipient
      end

      def trade_license?
        inventory = character.inventory
        return false unless inventory
        return true if inventory.metadata.to_h["trade_license"] == true

        inventory.inventory_items.includes(:item_template).any? do |item|
          key = item.item_template.key.to_s.downcase
          name = item.item_template.name.to_s.downcase
          key.include?("license") || name.include?("license")
        end
      end

      def wallet_for(target_character)
        target_character.user.currency_wallet || target_character.user.create_currency_wallet!(nv_balance: 0)
      end

      def decimal_value(value)
        BigDecimal(value.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def transfer_metadata(item, quantity)
        {
          "item_template_id" => item.item_template_id,
          "item" => item.item_template.name,
          "quantity" => quantity.to_i
        }
      end

      def success(message)
        Result.new(success: true, message:)
      end

      def failure(message)
        Result.new(success: false, message:)
      end
    end
  end
end
