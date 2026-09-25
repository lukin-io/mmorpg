# frozen_string_literal: true

module Arena
  # Localized combat-log phrase builders. Messages are persisted as rendered
  # strings so older fights keep their original locale snapshot.
  module CombatLogMessages
    module_function

    def t(key, **opts)
      I18n.t("game.combat_log.#{key}", **opts)
    end

    def zone(body_part)
      I18n.t("game.combat.body_parts.#{body_part}", default: body_part.to_s)
    end

    def fight_begins
      t("fight_begins")
    end

    def fight_timeout
      t("fight_timeout")
    end

    def fight_surrender
      t("fight_surrender")
    end

    def victory_named(name)
      t("victory_named", name:)
    end

    def victory_side(side)
      t("victory_side", side: side.to_s.upcase)
    end

    def draw
      t("draw")
    end

    def timeout_draw(name)
      t("timeout_draw", name:)
    end

    def timeout_victory(name)
      t("timeout_victory", name:)
    end

    def turn_submitted(name)
      t("turn_submitted", name:)
    end

    def resolving_round(round)
      t("resolving_round", round:)
    end

    def missed(attacker, target, body_part)
      t("missed", attacker:, target:, zone: zone(body_part))
    end

    def dodged(defender, attacker, body_part)
      t("dodged", defender:, attacker:, zone: zone(body_part))
    end

    def blocked(defender, attacker, body_part)
      t("blocked", defender:, attacker:, zone: zone(body_part))
    end

    def block_failed(defender, attacker, body_part)
      t("block_failed", defender:, attacker:, zone: zone(body_part))
    end

    def physical_hit(attacker, target, attack_type, body_part, damage, current_hp, max_hp, critical: false)
      action_name = Game::Combat::ActionCatalog.attack_config(attack_type)["name"].presence
      z = zone(body_part)
      if action_name.present? && !%w[simple aimed].include?(attack_type.to_s)
        key = critical ? "skill_critical" : "skill_hit"
        t(key, attacker:, target:, skill: action_name, zone: z, damage:, hp: current_hp, max_hp:)
      elsif critical
        t("critical_hit", attacker:, target:, zone: z, damage:, hp: current_hp, max_hp:)
      else
        t("hit", attacker:, target:, zone: z, damage:, hp: current_hp, max_hp:)
      end
    end

    def defeated(name)
      t("defeated", name:)
    end

    def defeated_short
      t("defeated_short")
    end

    def surrendered(name)
      t("surrendered", name:)
    end

    def loot_nothing(searcher, npc)
      t("loot_nothing", searcher:, npc:)
    end

    def loot_found(searcher, npc, found)
      t("loot_found", searcher:, npc:, found:)
    end

    def loot_failed(searcher, npc, message)
      t("loot_failed", searcher:, npc:, message:)
    end

    def defensive_stance(name, parts)
      t("defensive_stance", name:, parts:)
    end

    def defensive_stance_simple(name)
      t("defensive_stance_simple", name:)
    end

    def xp_gain(name, amount)
      t("xp_gain", name:, amount:)
    end

    def durability_loss(name)
      t("durability_loss", name:)
    end

    def item_award(item_name, quantity)
      suffix = quantity.to_i > 1 ? " x#{quantity}" : ""
      t("item_award", name: item_name, suffix:)
    end

    def funds_award(amount, currency)
      t("funds_award", amount:, currency:)
    end

    def npc_attack(npc, target, body_part, damage, critical: false)
      t(critical ? "npc_critical" : "npc_hit", npc:, target:, zone: zone(body_part), damage:)
    end
  end
end
