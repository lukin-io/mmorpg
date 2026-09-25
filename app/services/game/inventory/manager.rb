# frozen_string_literal: true

module Game
  module Inventory
    # Manager enforces slot/weight limits plus stack handling for character inventories.
    #
    # Purpose: Manages inventory operations including adding/removing items, stacking,
    #          using consumables, and sorting.
    #
    # Instance Usage:
    #   Game::Inventory::Manager.new(inventory:).add_item!(item_template:, quantity: 5)
    #
    # Class Method Usage:
    #   Game::Inventory::Manager.use_item(character, inventory_item)
    #   Game::Inventory::Manager.sort_inventory!(inventory, by: :type)
    #
    # Returns:
    #   InventoryItem (stack) that received the change.
    class Manager
      # Use a consumable item from inventory
      #
      # @param character [Character] the character using the item
      # @param inventory_item [InventoryItem] the item to use
      # @return [Hash] result with :success, :message or :error keys
      def self.use_item(character, inventory_item)
        template = inventory_item.item_template

        unless template.consumable?
          return {success: false, error: I18n.t("game.inventory.cannot_use")}
        end

        requirements = Game::Inventory::RequirementChecker.call(character:, item: inventory_item)
        return {success: false, error: requirements[:error]} unless requirements[:allowed]

        result = apply_item_effect(character, inventory_item)
        return result unless result[:success]

        consume_item_unit!(inventory_item) unless result[:defer_consume]
        result
      end

      def self.discard_item(inventory_item)
        if inventory_item.protected_from_discard?
          return {success: false, error: I18n.t("game.inventory.cannot_discard")}
        end

        decrement_inventory_weight!(inventory_item.inventory, inventory_item.weight * inventory_item.quantity)
        inventory_item.destroy!
        {success: true, message: I18n.t("game.inventory.item_discarded")}
      end

      def self.consume_item_unit!(inventory_item)
        if inventory_item.durable?
          remaining_durability = inventory_item.decrement_durability!
          return if remaining_durability.positive?
        end

        if inventory_item.quantity > 1
          inventory_item.decrement!(:quantity)
          decrement_inventory_weight!(inventory_item.inventory, inventory_item.weight)
          inventory_item.reset_durability!
        else
          decrement_inventory_weight!(inventory_item.inventory, inventory_item.weight)
          inventory_item.destroy!
        end
      end

      private_class_method :consume_item_unit!

      # Sort inventory items by specified criteria
      #
      # @param inventory [Inventory] the inventory to sort
      # @param by [Symbol] sort criteria (:type, :name)
      # @return [void]
      def self.sort_inventory!(inventory, by: :type)
        items = inventory.inventory_items.includes(:item_template).to_a

        sorted = case by
        when :type
          items.sort_by { |i| [i.item_template.item_type || "", i.item_template.name] }
        when :name
          items.sort_by { |i| i.item_template.name }
        else
          items
        end

        sorted.each_with_index do |item, index|
          item.update_column(:slot_index, index)
        end
      end

      # Apply item effect based on item type
      #
      # @param character [Character] the character to apply effect to
      # @param template [ItemTemplate] the item template with effect data
      # @return [Hash] result with :success and :message or :error
      def self.apply_item_effect(character, inventory_item)
        template = inventory_item.item_template
        stats = inventory_item.effect_modifiers
        notes = []

        if truthy_effect?(stats["join_as_protector"]) || template.key.to_s == Game::Combat::AssaultScrolls::PROTECTION_KEY
          return {
            success: true,
            defer_consume: true,
            redirect: Rails.application.routes.url_helpers.combat_interventions_path,
            message: I18n.t("game.combat.protector_choose_fight")
          }
        end

        if stats["assault_scroll_kind"].present? || truthy_effect?(template.enhancement_rules.to_h["assault_scroll"])
          kind = Game::Combat::AssaultScrolls.normalize_kind(
            stats["assault_scroll_kind"].presence || preferred_kind_from_key(template.key)
          )
          character.update!(
            metadata: character.metadata.to_h.merge("preferred_assault_scroll_kind" => kind)
          )
          return {
            success: true,
            defer_consume: true,
            message: I18n.t("game.combat.assault_scroll_armed", kind: I18n.t("game.combat.assault_kind.#{kind}"))
          }
        end

        if truthy_effect?(stats["clear_light_injury"])
          removed = Game::Combat::InjuryState.new(character:).clear_light!
          notes << I18n.t("game.injuries.cleared_light", count: removed) if removed.positive?
        end

        if stats["clear_injury_tier"].present?
          tier = stats["clear_injury_tier"].to_s
          removed = Game::Combat::InjuryState.new(character:).clear_up_to!(tier)
          notes << I18n.t("game.injuries.cleared_tier", tier: I18n.t("game.injuries.severity.#{tier}", default: tier), count: removed) if removed.positive?
        end

        buff_mods = stats["buff"].is_a?(Hash) ? stats["buff"] : {}
        buff_duration = stats["buff_duration_seconds"].to_i
        if buff_mods.present? || buff_duration.positive?
          buff_mods = stats.except(
            "buff", "buff_duration_seconds", "heal_hp", "restore_mp",
            "clear_light_injury", "clear_injury_tier"
          ) if buff_mods.blank?
          Characters::TimedBuffs.new(character:).apply!(
            key: template.key,
            label: template.display_name,
            mods: buff_mods,
            duration_seconds: buff_duration.positive? ? buff_duration : 1.hour.to_i
          )
          minutes = (buff_duration.positive? ? buff_duration : 1.hour.to_i) / 60
          notes << I18n.t(
            "game.inventory.buff_applied",
            name: template.display_name,
            minutes: minutes
          )
        end

        if stats["heal_hp"] && buff_mods.blank? && !buff_duration.positive?
          amount = stats["heal_hp"].to_i
          actual_healed = Characters::VitalsService.new(character).apply_healing(amount, source: template.name)
          notes << I18n.t("game.inventory.restored_hp", amount: actual_healed)
        end

        if stats["restore_mp"]
          amount = stats["restore_mp"].to_i
          actual_restored = Characters::VitalsService.new(character).restore_mana(amount, source: template.name)
          notes << I18n.t("game.inventory.restored_mp", amount: actual_restored)
        end

        if truthy_effect?(stats["reset_allocation"])
          character.update!(
            allocated_stats: {},
            passive_skills: {},
            stat_points_available: character.stat_points_available.to_i + allocated_stat_points(character),
            combat_skill_points: character.combat_skill_points.to_i + allocated_skill_points(character, :combat),
            peace_skill_points: character.peace_skill_points.to_i + allocated_skill_points(character, :peace)
          )
          character.clear_passive_skill_cache!
          notes << I18n.t("game.inventory.reset_allocation")
        end

        return {success: true, message: notes.join(" ")} if notes.any?

        # Default case - item has no known effect
        {success: false, error: I18n.t("game.inventory.no_usable_effect")}
      end

      def self.decrement_inventory_weight!(inventory, delta)
        return unless delta.to_i.positive?

        inventory.update!(current_weight: [inventory.current_weight - delta.to_i, 0].max)
      end

      private_class_method :apply_item_effect, :decrement_inventory_weight!

      def self.truthy_effect?(value)
        return false if value.nil?

        value == true || value.to_s == "true" || value.to_i == 1
      end

      def self.preferred_kind_from_key(key)
        case key.to_s
        when "assault_scroll_peaceful" then "peaceful"
        when "assault_scroll_bloody", "combat_trauma_scroll" then "bloody"
        else "normal"
        end
      end

      def self.allocated_stat_points(character)
        character.allocated_stats.to_h.values.sum(&:to_i)
      end

      def self.allocated_skill_points(character, pool)
        Game::Skills::PassiveSkillRegistry.by_pool(pool).sum do |skill|
          character.base_passive_skill_level(skill[:key]).positive? ? 1 : 0
        end
      end

      private_class_method :truthy_effect?, :preferred_kind_from_key, :allocated_stat_points, :allocated_skill_points

      def initialize(inventory:)
        @inventory = inventory
      end

      # Adds the complete requested quantity while holding the authoritative
      # inventory lock. The nested transaction is a savepoint when a caller
      # already owns a wider gameplay transaction, so a rescued capacity error
      # cannot leave an earlier stack or weight increment persisted.
      #
      # @param item_template [ItemTemplate] stable item definition to add
      # @param quantity [Integer] number of units to add
      # @return [InventoryItem] the last stack that received units
      # @raise [CapacityExceededError] when every unit cannot fit
      def add_item!(item_template:, quantity: 1)
        ApplicationRecord.transaction(requires_new: true) do
          inventory.lock!
          persist_item_stacks!(item_template:, quantity:)
        end
      end

      def remove_item!(item_template:, quantity: 1)
        remaining = quantity
        inventory.inventory_items.where(item_template:).order(:created_at).each do |stack|
          break if remaining <= 0

          to_remove = [remaining, stack.quantity].min
          stack.decrement!(:quantity, to_remove)
          decrement_weight!(stack.weight * to_remove)
          remaining -= to_remove
          stack.destroy if stack.quantity.zero?
        end

        raise InventoryUnderflowError, I18n.t("game.inventory.not_enough_items") if remaining.positive?
      end

      private

      class CapacityExceededError < StandardError; end
      class InventoryUnderflowError < StandardError; end

      attr_reader :inventory

      def find_or_build_stack(item_template:)
        stack = inventory.inventory_items.where(item_template:, equipped: false).order(:created_at).detect do |existing|
          existing.quantity < item_template.stack_limit
        end
        return stack if stack

        # Ashen soft capacity: stack count is unlimited. Mass may exceed
        # carrying_capacity (overweight slows travel); money/NV gates Shop buys.
        inventory.inventory_items.build(
          item_template:,
          quantity: 0,
          weight: item_template.weight
        )
      end

      def persist_item_stacks!(item_template:, quantity:)
        remaining = quantity
        last_stack = nil

        while remaining.positive?
          stack = find_or_build_stack(item_template:)
          capacity = item_template.stack_limit - stack.quantity
          raise CapacityExceededError, I18n.t("game.inventory.stack_limit_exceeded") if capacity <= 0

          to_add = [remaining, capacity].min

          if stack.new_record?
            stack.quantity = to_add
            stack.save!
          else
            stack.increment!(:quantity, to_add)
          end
          increment_weight!(item_template.weight * to_add)
          remaining -= to_add
          last_stack = stack
        end

        last_stack
      end

      def increment_weight!(delta)
        inventory.increment!(:current_weight, delta)
      end

      def decrement_weight!(delta)
        inventory.decrement!(:current_weight, delta)
      end
    end
  end
end
