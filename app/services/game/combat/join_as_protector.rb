# frozen_string_literal: true

module Game
  module Combat
    # Consumes a Protection scroll and joins a live ArenaMatch as a helper on
    # team A or B. Server-authoritative mid-fight intervention.
    class JoinAsProtector
      class ViolationError < StandardError; end

      Result = Struct.new(:success, :match, :message, keyword_init: true)
      TEAMS = %w[a b].freeze

      def initialize(character:, match_id:, team:)
        @character = character
        @match_id = match_id.to_i
        @team = team.to_s.downcase
      end

      def self.live_joinable_matches
        ArenaMatch.live.includes(arena_participations: [:character, :npc_template]).order(started_at: :desc).limit(40)
      end

      def call
        match = nil
        ActiveRecord::Base.transaction do
          character.with_lock do
            character.reload
            match = ArenaMatch.lock.find_by(id: match_id)
            validate!(match)
            consume_protection_scroll!
            ArenaParticipation.create!(
              arena_match: match,
              character:,
              user: character.user,
              team:,
              joined_at: Time.current,
              metadata: {
                "protector" => true,
                "joined_via" => "protection_scroll"
              }
            )
            character.update!(in_combat: true, last_combat_at: Time.current) if match.live?
          end
        end

        Arena::CombatBroadcaster.new(match).broadcast_state_refresh(reason: :protector_joined)
        Arena::CombatBroadcaster.new(match).broadcast_system_message(
          I18n.t("game.combat.protector_joined_log", name: character.name, team: team.upcase)
        )

        Result.new(
          success: true,
          match:,
          message: I18n.t("game.combat.protector_joined", team: team.upcase)
        )
      rescue ViolationError => error
        Result.new(success: false, message: error.message)
      end

      private

      attr_reader :character, :match_id, :team

      def validate!(match)
        raise ViolationError, I18n.t("game.combat.protector_match_missing") unless match
        raise ViolationError, I18n.t("game.combat.protector_not_live") unless match.live?
        raise ViolationError, I18n.t("game.combat.protector_bad_team") unless TEAMS.include?(team)
        raise ViolationError, I18n.t("game.flashes.fight_still_active") if already_fighting?
        if match.arena_participations.exists?(character_id: character.id)
          raise ViolationError, I18n.t("game.combat.protector_already_in")
        end
        raise ViolationError, I18n.t("game.flashes.disembark_first") if character.active_airship_journey
        if MovementCommand.moving.where(character:).exists?
          raise ViolationError, I18n.t("game.flashes.movement_in_progress")
        end
      end

      def already_fighting?
        character.in_combat? ||
          character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
      end

      def consume_protection_scroll!
        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: AssaultScrolls::PROTECTION_KEY)
        raise ViolationError, I18n.t("game.combat.protector_scroll_missing") unless template

        inventory = character.inventory
        raise ViolationError, I18n.t("game.combat.protector_scroll_missing") unless inventory

        stack = inventory.inventory_items.find_by(item_template: template, equipped: false)
        if stack.blank? || stack.quantity.to_i <= 0
          raise ViolationError, I18n.t("game.combat.protector_scroll_missing")
        end

        Game::Inventory::Manager.new(inventory:).remove_item!(item_template: template, quantity: 1)
      rescue Game::Inventory::Manager::InventoryUnderflowError
        raise ViolationError, I18n.t("game.combat.protector_scroll_missing")
      end
    end
  end
end
