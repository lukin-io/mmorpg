# frozen_string_literal: true

module Game
  module World
    # Ashen Obelisk: bind current coordinates and recall for NV.
    class ObeliskRecall
      Result = Struct.new(:success, :message, keyword_init: true)
      META_KEY = "ashen_obelisk"
      RECALL_COST = 15

      def initialize(character:, action:)
        @character = character
        @action = action.to_s
      end

      def self.bound_for(character)
        raw = character.metadata.to_h[META_KEY]
        return nil unless raw.is_a?(Hash)

        raw.deep_stringify_keys
      end

      def call
        case action
        when "bind" then bind!
        when "recall" then recall!
        else
          Result.new(success: false, message: I18n.t("game.buildings.obelisk_bad_action"))
        end
      end

      private

      attr_reader :character, :action

      def bind!
        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.obelisk_in_combat"))
          end
          if character.active_airship_journey
            return Result.new(success: false, message: I18n.t("game.flashes.disembark_first"))
          end

          position = character.position
          return Result.new(success: false, message: I18n.t("game.buildings.obelisk_no_position")) unless position

          payload = {
            "zone_id" => position.zone_id,
            "x" => position.x,
            "y" => position.y,
            "zone_name" => position.zone.name,
            "bound_at" => Time.current.iso8601
          }
          character.update!(metadata: character.metadata.to_h.merge(META_KEY => payload))
          Game::World::ResumeContext.new(character:).remember_world! if position.zone.outdoor?
          Result.new(
            success: true,
            message: I18n.t("game.buildings.obelisk_bound", place: position.zone.display_name || position.zone.name)
          )
        end
      end

      def recall!
        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.obelisk_in_combat"))
          end
          if character.active_airship_journey
            return Result.new(success: false, message: I18n.t("game.flashes.disembark_first"))
          end
          if MovementCommand.moving.where(character:).exists?
            return Result.new(success: false, message: I18n.t("game.flashes.movement_in_progress"))
          end

          bound = self.class.bound_for(character)
          return Result.new(success: false, message: I18n.t("game.buildings.obelisk_unbound")) unless bound

          zone = Zone.find_by(id: bound["zone_id"])
          return Result.new(success: false, message: I18n.t("game.buildings.obelisk_lost")) unless zone

          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          if wallet.nv_balance.to_i < RECALL_COST
            return Result.new(success: false, message: I18n.t("game.buildings.obelisk_short", amount: RECALL_COST))
          end

          position = character.position
          return Result.new(success: false, message: I18n.t("game.buildings.obelisk_no_position")) unless position

          already_there = position.zone_id == zone.id && position.x == bound["x"].to_i && position.y == bound["y"].to_i
          if already_there
            return Result.new(success: false, message: I18n.t("game.buildings.obelisk_already_there"))
          end

          wallet.adjust!(
            amount: -RECALL_COST,
            reason: "ashen.obelisk_recall",
            metadata: {"zone_id" => zone.id, "x" => bound["x"], "y" => bound["y"]}
          )
          position.update!(
            zone:,
            x: bound["x"].to_i,
            y: bound["y"].to_i,
            state: :active,
            last_action_at: Time.current
          )
          Game::World::ResumeContext.new(character:).remember_world!
          Result.new(
            success: true,
            message: I18n.t(
              "game.buildings.obelisk_recalled",
              place: zone.display_name || zone.name,
              amount: RECALL_COST
            )
          )
        end
      end
    end
  end
end
