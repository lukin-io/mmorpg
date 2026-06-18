# frozen_string_literal: true

module Game
  module Inventory
    # Persists and wears Neverlands-style named equipment sets using inventory metadata.
    class EquipmentSetService
      Result = Struct.new(:success, :message, :set_name, keyword_init: true)

      def initialize(character:)
        @character = character
        @inventory = character.inventory || character.create_inventory!
      end

      def save!(name)
        normalized = normalize_name(name)
        return failure("Equipment set name is required.") if normalized.blank?
        return failure("Equipment set name is too long.") if normalized.length > 30

        equipped = inventory.inventory_items.equipped.order(:equipment_slot).to_a
        return failure("No equipped items to save.") if equipped.empty?

        sets = equipment_sets
        sets[normalized] = {
          "slots" => equipped.to_h { |item| [item.equipment_slot, item.id] },
          "saved_at" => Time.current.iso8601
        }
        persist_sets!(sets)

        success("Equipment set saved.", normalized)
      end

      def wear!(name)
        normalized = normalize_name(name)
        set = equipment_sets[normalized]
        return failure("Equipment set not found.") unless set

        slot_items = set.fetch("slots", {})
        return failure("Equipment set is empty.") if slot_items.empty?

        items_by_slot = slot_items.to_h do |slot, item_id|
          item = inventory.inventory_items.find_by(id: item_id)
          return failure("Equipment set cannot be worn with current item state.") unless item

          check = RequirementChecker.call(character:, item:)
          return failure(check[:error]) unless check[:allowed]

          [slot, item]
        end

        ApplicationRecord.transaction do
          inventory.lock!
          inventory.inventory_items.equipped.update_all(equipped: false, equipment_slot: nil, updated_at: Time.current)

          items_by_slot.each do |slot, item|
            item.update!(equipped: true, equipment_slot: slot)
          end
        end

        success("Equipment set worn.", normalized)
      end

      def delete!(name)
        normalized = normalize_name(name)
        sets = equipment_sets
        return failure("Equipment set not found.") unless sets.key?(normalized)

        sets.delete(normalized)
        persist_sets!(sets)
        success("Equipment set deleted.", normalized)
      end

      def all
        equipment_sets
      end

      private

      attr_reader :character, :inventory

      def equipment_sets
        inventory.metadata.to_h.fetch("equipment_sets", {})
      end

      def persist_sets!(sets)
        inventory.update!(metadata: inventory.metadata.to_h.merge("equipment_sets" => sets))
      end

      def normalize_name(name)
        name.to_s.strip
      end

      def success(message, set_name)
        Result.new(success: true, message:, set_name:)
      end

      def failure(message)
        Result.new(success: false, message:)
      end
    end
  end
end
