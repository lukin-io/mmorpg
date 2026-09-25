# frozen_string_literal: true

module Game
  module Economy
    # Mist-oriented soft curves: convenience and craft sinks beat raw NL gos tables.
    # Combat players without craft mats pay more fatigue / heal slower via existing
    # bandage kits — this module only exposes seasonal craft premiums and tips.
    class MistCurve
      def self.craft_sell_bonus(item_key, at: Time.current)
        return 1.0 unless Game::Seasons::Catalog.active?(at:)

        keys = Array(Game::Seasons::Catalog.current["craft_demand_keys"]).map(&:to_s)
        keys.include?(item_key.to_s) ? 1.15 : 1.0
      end

      # Soft recommendation line for UI — no authoritative combat change.
      def self.combat_needs_crafter_hint
        I18n.t("game.economy.combat_needs_crafter")
      end
    end
  end
end
