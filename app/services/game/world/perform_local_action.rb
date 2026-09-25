# frozen_string_literal: true

module Game
  module World
    # Starts a captured current-cell action from an accepted owned offer. Under
    # the character/offer lock it revalidates the cell, resolves interruption,
    # and atomically persists the immediate result, configured deadline and
    # Drink's fatigue recovery / Dig-Look-Fish gather awards. Retrying a started
    # offer returns its original result without applying recovery again.
    class PerformLocalAction
      Result = Struct.new(:success, :message, :local_action, :action_offer, :interruption, keyword_init: true)
      BAIT_KEY = "ashen_bait"

      def initialize(character:, tile:, local_action_type:, action_offer:, clock: -> { Time.current }, rules: Rules.default)
        @character = character
        @tile = tile
        @local_action_type = local_action_type.to_s
        @action_offer = action_offer
        @clock = clock
        @rules = rules
      end

      def call
        character.with_lock do
          character.reload
          @tile = MapTileTemplate.find_by(id: tile&.id)
          next failure(I18n.t("game.world.local_action_unavailable")) unless tile
          next failure(I18n.t("game.world.local_action_not_implemented")) unless MapTileTemplate.local_action_implemented?(local_action_type)

          @action_offer = WorldActionOffer.where(character:).lock.find_by(id: action_offer&.id)
          next failure(I18n.t("game.world.action_offer_mismatch")) unless offer_matches_action?

          if action_offer.local_action_ends_at && (action_offer.accepted? || action_offer.completed?)
            LocalActionState.new(character:, clock:).call
            action_offer.reload
            next success if action_offer.accepted? || action_offer.completed?
          end
          next failure(I18n.t("game.world.action_offer_not_accepted")) unless action_offer.accepted?
          next failure(I18n.t("game.world.local_action_wrong_cell")) unless tile_matches_position? && action_offer.matches_position?(character.position)
          next failure(I18n.t("game.world.local_action_still_in_progress")) if LocalActionState.new(character:, clock:).call

          local_action = tile.local_action(local_action_type)
          next failure(I18n.t("game.world.local_action_unavailable")) unless local_action

          interruption = InterruptAction.new(character:).call
          if interruption.interrupted?
            action_offer.complete!
            next Result.new(success: true, message: interruption.message, local_action:, action_offer:, interruption:)
          end

          now = clock.call
          result_message = MapTileTemplate.player_local_action_message(
            local_action_type,
            local_action["result_message"]
          )
          if interruption.hint.present?
            result_message = "#{result_message} #{interruption.hint}"
          end
          effect = apply_effect(at: now)
          if effect["gather_skipped"] == "depleted"
            depleted_message = I18n.t("game.world.local_action.resources_regrowing")
            action_offer.update!(metadata: action_offer.metadata.to_h.merge(effect).merge(
              "local_action_result" => depleted_message
            ))
            action_offer.complete!
            next failure(depleted_message)
          end
          if effect["gather_item_key"].present?
            result_message = I18n.t(
              "game.world.local_action.gather_success",
              label: effect["gather_label"],
              qty: effect["gather_quantity"]
            )
          elsif effect["gather_skipped"] == "no_tool"
            result_message = I18n.t(
              "game.world.local_action.need_tool",
              tool: ItemTemplate.find_by(key: effect["gather_tool_key"])&.name || effect["gather_tool_key"]
            )
          elsif effect["gather_skipped"] == "no_hook"
            hook = ItemTemplate.find_by(key: effect["gather_hook_key"])&.name || effect["gather_hook_key"]
            result_message = I18n.t("game.world.local_action.need_hook", hook: hook)
          elsif effect["gather_skipped"] == "slip"
            result_message = I18n.t(
              "game.world.local_action.fishing_slip",
              skill: effect["fishing_skill"],
              need: effect["fishing_required"]
            )
          elsif effect["gather_skipped"] == "no_bait"
            result_message = I18n.t("game.world.local_action.no_bait_message")
          end
          duration = action_duration_seconds(effect)
          action_offer.update!(metadata: action_offer.metadata.to_h.merge(
            "local_action_ends_at" => (now + duration).iso8601(6),
            "local_action_result" => result_message,
            "label" => MapTileTemplate.player_local_action_label(
              local_action_type,
              local_action["label"]
            )
          ).merge(effect))
          cancel_sibling_offers!(now)

          success(local_action:)
        end
      end

      private

      attr_reader :character, :tile, :local_action_type, :action_offer, :clock, :rules

      def action_duration_seconds(effect)
        base = rules.local_action_duration_seconds(local_action_type)
        duration = if local_action_type == "fishing"
          FishingCatalog.duration_seconds(base:, character:, rod_key: effect["gather_tool_key"])
        else
          base
        end
        speed_percent = Characters::TimedBuffs.new(character:).modifier("gather_speed")
        [duration * (1.0 - (speed_percent / 100.0)), 5].max.round
      end

      def apply_effect(at:)
        case local_action_type
        when "drinking"
          nature_child = character.owns_perk?(:nature_child)
          points = rules.drinking_fatigue_recovery_points(nature_child:)
          mult = Game::Shop::PremiumPass.perks_for(character.user)[:fatigue_mult].to_f
          points = (points * mult).round if mult > 1.0
          applied = ::Characters::FatigueService.new(character:, rules:).recover!(amount: points, at:)
          {
            "fatigue_recovery_points" => points,
            "fatigue_recovery_applied" => applied,
            "fatigue_recovered_at" => at.iso8601(6),
            "nature_child" => nature_child,
            "premium_fatigue_mult" => mult
          }
        when "digging", "resource_search", "fishing"
          grant_gather!
        else
          {}
        end
      end

      def grant_gather!
        Game::World::AshenGatherNodes.ensure!
        Game::Professions::Templates.ensure_craft_items!
        Game::World::GatherTools.ensure_templates!

        tool_key = GatherTools.required_key_for(local_action_type)
        if tool_key && !GatherTools.owned?(character, tool_key)
          return {"gather_skipped" => "no_tool", "gather_tool_key" => tool_key}
        end

        effect = {}
        rod = nil
        if local_action_type == "fishing"
          rod = FishingCatalog.best_rod(character)
          return {"gather_skipped" => "no_tool", "gather_tool_key" => "ashen_fishing_rod"} unless rod

          tool_key = rod.key
        end

        yield_row = GatherYield.new(tile:, local_action_type:, character:, clock:).call
        return effect.merge("gather_skipped" => "none") unless yield_row
        return effect.merge("gather_skipped" => "depleted") if yield_row.depleted

        if local_action_type == "fishing"
          hook_meta = consume_fishing_hook!(yield_row.item_key)
          return hook_meta if hook_meta["gather_skipped"]

          effect.merge!(hook_meta)
          unless fishing_lands?(yield_row.item_key, rod_key: tool_key)
            return effect.merge(
              "gather_skipped" => "slip",
              "gather_tool_key" => tool_key,
              "fishing_skill" => FishingCatalog.effective_skill(character, rod_key: tool_key),
              "fishing_required" => FishingCatalog.skill_required_for(yield_row.item_key)
            )
          end
        end

        template = ItemTemplate.find_by(key: yield_row.item_key)
        return effect.merge("gather_skipped" => yield_row.item_key) unless template

        qty = yield_row.quantity.to_i + Game::Shop::PremiumPass.perks_for(character.user)[:gather_bonus].to_i
        qty = [qty, 1].max

        inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
        Game::Inventory::Manager.new(inventory:).add_item!(
          item_template: template,
          quantity: qty
        )
        deplete_group!(yield_row)
        GatherTools.wear!(character, tool_key)
        FishingCatalog.gain_skill!(character) if local_action_type == "fishing"
        Game::WorldEvents::TournamentScore.record_fish!(character:, amount: qty) if local_action_type == "fishing"
        activity_kind =
          case local_action_type
          when "fishing" then "catch_fish"
          when "resource_search" then "gather_herb"
          when "digging" then "dig_wood"
          end
        Game::Activity::Tracker.new(character:).record!(kind: activity_kind, amount: qty) if activity_kind
        effect.merge(
          "gather_item_key" => template.key,
          "gather_quantity" => qty,
          "gather_label" => yield_row.label,
          "gather_tool_key" => tool_key,
          "fishing_skill" => (FishingCatalog.effective_skill(character, rod_key: tool_key) if local_action_type == "fishing")
        ).compact
      rescue Game::Inventory::Manager::CapacityExceededError
        {"gather_skipped" => "full"}
      rescue Game::Inventory::Manager::InventoryUnderflowError
        {"gather_skipped" => "no_hook"}
      end

      def deplete_group!(yield_row)
        tile.with_lock do
          tile.reload
          metadata = tile.metadata.to_h.deep_dup
          depletion = metadata["resource_depletion"].is_a?(Hash) ? metadata["resource_depletion"].dup : {}
          depletion[yield_row.group_key] = (clock.call + yield_row.respawn_seconds).iso8601
          tile.update!(metadata: metadata.merge("resource_depletion" => depletion))
        end
      end

      def consume_fishing_hook!(fish_key)
        inventory = character.inventory
        return {"gather_skipped" => "no_hook"} unless inventory

        hook_key = FishingCatalog.hook_for_fish(fish_key)
        return {"gather_skipped" => "no_hook", "gather_hook_key" => hook_key} if hook_key.blank?

        FishingCatalog.ensure_templates!
        hook_template = ItemTemplate.find_by(key: hook_key)
        return {"gather_skipped" => "no_hook", "gather_hook_key" => hook_key} unless hook_template

        owned = inventory.inventory_items.where(item_template: hook_template, equipped: false).sum(:quantity)
        return {"gather_skipped" => "no_hook", "gather_hook_key" => hook_key} if owned < 1

        Game::Inventory::Manager.new(inventory:).remove_item!(item_template: hook_template, quantity: 1)
        {"hook_consumed" => 1, "gather_hook_key" => hook_key}
      end

      def fishing_lands?(fish_key, rod_key:)
        return true if FishingCatalog.guaranteed?(character, fish_key, rod_key:)

        chance = 1.0 - FishingCatalog.slip_chance(character, fish_key, rod_key:)
        Random.rand < chance
      end

      def consume_bait!
        inventory = character.inventory
        return {"gather_skipped" => "no_bait"} unless inventory

        bait_template = ItemTemplate.find_by(key: BAIT_KEY)
        return {"gather_skipped" => "no_bait"} unless bait_template

        owned = inventory.inventory_items.where(item_template: bait_template, equipped: false).sum(:quantity)
        return {"gather_skipped" => "no_bait"} if owned < 1

        Game::Inventory::Manager.new(inventory:).remove_item!(item_template: bait_template, quantity: 1)
        {"bait_consumed" => 1}
      end

      def offer_matches_action?
        action_offer &&
          action_offer.action_type == MapTileTemplate.world_action_type_for(local_action_type) &&
          action_offer.target_type == "MapTileTemplate" &&
          action_offer.target_id == tile.id
      end

      def tile_matches_position?
        position = character.position
        position.present? &&
          position.zone.name == tile.zone &&
          position.x == tile.x &&
          position.y == tile.y
      end

      def failure(message)
        Result.new(success: false, message:, local_action: nil)
      end

      def success(local_action: nil)
        Result.new(success: true, message: action_offer.local_action_result, local_action:, action_offer:)
      end

      def cancel_sibling_offers!(now)
        WorldActionOffer.offered.where(character:).update_all(
          status: WorldActionOffer.statuses.fetch("cancelled"), updated_at: now
        )
        MovementCommand.offered.where(character:).update_all(
          status: MovementCommand.statuses.fetch("cancelled"), processed_at: now, updated_at: now
        )
      end
    end
  end
end
