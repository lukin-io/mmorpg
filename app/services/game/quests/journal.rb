# frozen_string_literal: true

module Game
  module Quests
    # Character-scoped Ashen quest journal stored in metadata["ashen_quests"].
    class Journal
      META_KEY = "ashen_quests"
      STARTER_QUEST_KEY = "veil_lure_drill"

      Result = Data.define(:success, :message, :quest_key)

      def initialize(character:)
        @character = character
      end

      def entries
        Catalog.ordered.map { |quest| present(quest) }.sort_by do |entry|
          status_rank = {"active" => 0, "available" => 1, "locked" => 2, "completed" => 3}[entry[:status]] || 9
          [status_rank, entry[:quest]["sort"].to_i]
        end
      end

      def present(quest)
        key = quest.fetch("key")
        state = state_for(key)
        status = if state["status"] == "completed"
          "completed"
        elsif state["status"] == "active"
          "active"
        elsif requirements_met?(quest)
          "available"
        else
          "locked"
        end

        {
          quest:,
          status:,
          progress: progress_for(quest, state),
          target: objective_count(quest),
          completed_at: state["completed_at"],
          accepted_at: state["accepted_at"],
          where: where_for(quest)
        }
      end

      def accept!(quest_key)
        quest = Catalog.find(quest_key)
        return failure(quest_key, I18n.t("game.quests.unknown")) unless quest

        character.with_lock do
          character.reload
          state = state_for(quest_key)
          return failure(quest_key, I18n.t("game.quests.already_done")) if state["status"] == "completed"
          return failure(quest_key, I18n.t("game.quests.already_active")) if state["status"] == "active"
          return failure(quest_key, I18n.t("game.quests.locked")) unless requirements_met?(quest)

          write_state!(quest_key, {
            "status" => "active",
            "progress" => 0,
            "accepted_at" => Time.current.iso8601
          })
        end

        success(quest_key, I18n.t("game.quests.accepted", title: title_for(quest)))
      end

      # Quietly arms the first Ashen shore contract once. Safe to call every login.
      def ensure_starter!
        state = state_for(STARTER_QUEST_KEY)
        return if state["status"].in?(%w[active completed])

        accept!(STARTER_QUEST_KEY)
      end

      # Compact HUD label for the first active Ashen quest, if any.
      def active_chip
        entry = entries.find { |row| row[:status] == "active" }
        return nil unless entry

        quest = entry[:quest]
        title = title_for(quest)
        where = entry[:where]
        ready = entry[:progress].to_i >= entry[:target].to_i
        base =
          if ready
            I18n.t("game.quests.chip_ready", title:, progress: entry[:progress], target: entry[:target])
          else
            I18n.t("game.quests.chip", title:, progress: entry[:progress], target: entry[:target])
          end
        where.present? ? "#{base} · #{where}" : base
      end

      def active_chip_ready?
        entry = entries.find { |row| row[:status] == "active" }
        return false unless entry

        entry[:progress].to_i >= entry[:target].to_i
      end

      def turn_in!(quest_key)
        quest = Catalog.find(quest_key)
        return failure(quest_key, I18n.t("game.quests.unknown")) unless quest

        unlocked_titles = []
        character.with_lock do
          character.reload
          state = state_for(quest_key)
          return failure(quest_key, I18n.t("game.quests.not_active")) unless state["status"] == "active"

          unless objective_met?(quest, state)
            return failure(quest_key, I18n.t("game.quests.objective_incomplete"))
          end

          consume_delivery!(quest) if quest.dig("objective", "type") == "deliver_item"
          grant_rewards!(quest)
          write_state!(quest_key, state.merge(
            "status" => "completed",
            "progress" => objective_count(quest),
            "completed_at" => Time.current.iso8601
          ))
          unlocked_titles = auto_unlock!(quest)
        end

        message = I18n.t("game.quests.completed", title: title_for(quest))
        if unlocked_titles.any?
          message = "#{message} #{I18n.t("game.quests.unlocked", list: unlocked_titles.join(", "))}"
        end
        success(quest_key, message)
      end

      # Called after a solo NPC victory. Quiet no-op when nothing matches.
      def record_npc_kill!(npc_key:)
        key = npc_key.to_s
        return if key.blank?

        character.with_lock do
          character.reload
          Catalog.ordered.each do |quest|
            next unless quest.dig("objective", "type") == "kill_npc"
            next unless kill_matches_objective?(key, Array(quest.dig("objective", "npc_keys")).map(&:to_s))

            state = state_for(quest.fetch("key"))
            next unless state["status"] == "active"

            target = objective_count(quest)
            progress = [state["progress"].to_i + 1, target].min
            write_state!(quest.fetch("key"), state.merge("progress" => progress))
          end
        end
      end

      # Stand on a fortress cell.
      def record_fortress_visit!
        bump_objective!("visit_fortress")
      end

      # Cleared one dungeon pack floor.
      def record_pack_floor!(pack_key:)
        key = pack_key.to_s
        return if key.blank?

        character.with_lock do
          character.reload
          Catalog.ordered.each do |quest|
            next unless quest.dig("objective", "type") == "clear_pack_floor"
            keys = Array(quest.dig("objective", "pack_keys")).map(&:to_s)
            next if keys.any? && !keys.include?(key)

            state = state_for(quest.fetch("key"))
            next unless state["status"] == "active"

            target = objective_count(quest)
            progress = [state["progress"].to_i + 1, target].min
            write_state!(quest.fetch("key"), state.merge("progress" => progress))
          end
        end
      end

      # After gather/fishing, persist live bag counts onto deliver_item quest rows
      # so HUD/metadata match Journal#present without waiting for turn-in.
      def sync_delivery_progress!
        character.with_lock do
          character.reload
          Catalog.ordered.each do |quest|
            next unless quest.dig("objective", "type") == "deliver_item"

            state = state_for(quest.fetch("key"))
            next unless state["status"] == "active"

            progress = progress_for(quest, state)
            next if state["progress"].to_i == progress

            write_state!(quest.fetch("key"), state.merge("progress" => progress))
          end
        end
      end

      private

      def bump_objective!(type)
        character.with_lock do
          character.reload
          Catalog.ordered.each do |quest|
            next unless quest.dig("objective", "type") == type.to_s

            state = state_for(quest.fetch("key"))
            next unless state["status"] == "active"

            target = objective_count(quest)
            progress = [state["progress"].to_i + 1, target].min
            write_state!(quest.fetch("key"), state.merge("progress" => progress))
          end
        end
      end

      attr_reader :character

      def bag
        character.metadata.to_h.fetch(META_KEY, {})
      end

      def state_for(quest_key)
        bag.fetch(quest_key.to_s, {}).to_h
      end

      def write_state!(quest_key, state)
        next_bag = bag.merge(quest_key.to_s => state)
        character.update!(metadata: character.metadata.to_h.merge(META_KEY => next_bag))
      end

      def requirements_met?(quest)
        Array(quest["requires"]).map(&:to_s).all? do |required_key|
          state_for(required_key)["status"] == "completed"
        end
      end

      def auto_unlock!(quest)
        titles = []
        Array(quest["unlocks"]).map(&:to_s).each do |next_key|
          next_quest = Catalog.find(next_key)
          next unless next_quest

          state = state_for(next_key)
          next if state["status"].in?(%w[active completed])
          next unless requirements_met?(next_quest)

          write_state!(next_key, {
            "status" => "active",
            "progress" => 0,
            "accepted_at" => Time.current.iso8601
          })
          titles << title_for(next_quest)
        end
        titles
      end

      def objective_count(quest)
        quest.dig("objective", "count").to_i.clamp(1, 99)
      end

      # Soft-release: match exact keys, and treat av_* farm clones as their shore
      # base when quests list the shore cast (av_plague_rat ↔ plague_rat).
      def kill_matches_objective?(killed_key, objective_keys)
        return false if objective_keys.blank?

        candidates = [killed_key.to_s]
        candidates << killed_key.delete_prefix("av_") if killed_key.start_with?("av_")
        candidates << "av_#{killed_key}" unless killed_key.start_with?("av_")
        (candidates & objective_keys).any?
      end

      def progress_for(quest, state)
        target = objective_count(quest)
        case quest.dig("objective", "type")
        when "deliver_item"
          return target if state["status"] == "completed"

          [item_quantity(quest.dig("objective", "item_key")), target].min
        else
          state["progress"].to_i
        end
      end

      def objective_met?(quest, state)
        type = quest.dig("objective", "type").to_s
        return false if type.blank?

        case type
        when "kill_npc", "visit_fortress", "clear_pack_floor"
          state["progress"].to_i >= objective_count(quest)
        when "deliver_item"
          item_quantity(quest.dig("objective", "item_key")) >= objective_count(quest)
        else
          Rails.logger.warn("[quests] unsupported objective type=#{type} key=#{quest["key"]}")
          false
        end
      end

      def item_quantity(item_key)
        template = ItemTemplate.find_by(key: item_key.to_s)
        return 0 unless template

        character.inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
      end

      def consume_delivery!(quest)
        item_key = quest.dig("objective", "item_key").to_s
        needed = objective_count(quest)
        template = ItemTemplate.find_by!(key: item_key)
        remaining = needed
        character.inventory.inventory_items.where(item_template: template, equipped: false).order(:id).each do |row|
          break if remaining <= 0

          take = [row.quantity, remaining].min
          if take >= row.quantity
            row.destroy!
          else
            row.update!(quantity: row.quantity - take)
          end
          remaining -= take
        end
        raise ArgumentError, I18n.t("game.quests.missing_delivery_items") if remaining.positive?
      end

      def grant_rewards!(quest)
        reward = quest.fetch("reward", {})
        xp = reward["experience"].to_i
        if xp.positive?
          Players::Progression::LevelUpService.new(character:).apply_experience!(xp)
        end

        nv = reward["currency_nv"].to_i
        if nv.positive?
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          wallet.adjust!(
            amount: nv,
            reason: "quest.ashen_reward",
            metadata: {"quest_key" => quest.fetch("key")}
          )
        end

        item_key = reward["item_key"].presence
        return unless item_key

        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: item_key)
        if template.nil? && item_key.match?(/\Aset-.+-t\d+\z/)
          load Rails.root.join("db/seeds/ashen_veil_thematic_sets.rb")
          template = ItemTemplate.find_by(key: item_key)
        end
        return unless template

        inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
        begin
          Game::Inventory::Manager.new(inventory:).add_item!(
            item_template: template,
            quantity: 1
          )
        rescue Game::Inventory::Manager::CapacityExceededError
          # Soft-release: do not soft-lock turn-in when the bag is full; XP/NV still grant.
          Rails.logger.info(
            "[quests] skipped item reward #{item_key} for character=#{character.id} (inventory full)"
          )
        end
      end

      def title_for(quest)
        locale_key = I18n.locale.to_s.start_with?("ru") ? "title_ru" : "title_en"
        quest[locale_key].presence || quest["title_ru"] || quest.fetch("key")
      end

      def where_for(quest)
        locale_key = I18n.locale.to_s.start_with?("ru") ? "where_ru" : "where_en"
        quest[locale_key].presence || quest["where_ru"]
      end

      def success(quest_key, message)
        Result.new(success: true, message:, quest_key: quest_key.to_s)
      end

      def failure(quest_key, message)
        Result.new(success: false, message:, quest_key: quest_key.to_s)
      end
    end
  end
end
