# frozen_string_literal: true

module Game
  module Combat
    class TurnResolver
      Result = Struct.new(:log, :hp_changes, :effects, :battle, keyword_init: true)
      CombatantSnapshot = Struct.new(:stats)

      def initialize(attacker:, defender:, action:, rng: Random.new(1), battle: nil, ability: nil,
        log_writer: nil)
        @attacker = attacker
        @defender = defender
        @action = action
        @rng = rng
        @battle = battle
        @ability = ability
        @log_writer = log_writer || Game::Combat::LogWriter.new(battle:) if battle
      end

      def call
        ability_effects = parsed_ability_effects
        attacker_snapshot = combatant_snapshot(attacker)
        defender_snapshot = combatant_snapshot(defender)

        base_damage = damage_formula.call(attacker_snapshot, defender_snapshot) + ability_effects[:damage_bonus]
        crit_multiplier = crit_formula.call(attacker_snapshot, defender_snapshot)
        total_damage = [(base_damage * crit_multiplier).to_i, 1].max

        crit_suffix = ""
        crit_suffix = " (CRIT)" if crit_multiplier > 1
        log_entries = ["#{attacker.name} used #{action} for #{total_damage} damage#{crit_suffix}"]
        log_entries << "#{defender.name} suffered #{ability_effects[:status]}" if ability_effects[:status]

        apply_combat_effects(ability_effects)

        persist_logs(log_entries, total_damage:, effects: ability_effects)
        advance_battle_turn if battle

        Result.new(
          log: log_entries,
          hp_changes: {defender: -total_damage},
          effects: ability_effects,
          battle:
        )
      end

      private

      attr_reader :attacker, :defender, :action, :rng, :battle, :ability, :log_writer

      def damage_formula
        @damage_formula ||= Game::Formulas::DamageFormula.new(rng:)
      end

      def crit_formula
        @crit_formula ||= Game::Formulas::CritFormula.new(rng:)
      end

      def persist_logs(entries, total_damage:, effects:)
        return unless log_writer

        entries.each_with_index do |message, index|
          log_writer.append!(
            message:,
            payload: {
              attacker: attacker.name,
              attacker_id: attacker_id,
              defender: defender.name,
              defender_id: defender_id,
              action:,
              total_damage:,
              effects:,
              battle_type: battle&.battle_type,
              pvp_mode: battle&.pvp_mode,
              ability_id: ability&.id
            },
            round_number: battle.turn_number,
            sequence_offset: index
          )
        end
      end

      def advance_battle_turn
        order = battle.initiative_order.presence || battle.battle_participants.order(initiative: :desc).pluck(:id)
        order.rotate!
        battle.update!(initiative_order: order, turn_number: battle.turn_number + 1)
        effect_bookkeeper&.tick!
        @participants_by_character = nil
      end

      def apply_combat_effects(ability_effects)
        return unless battle && ability

        if ability_effects[:buffs].present?
          effect_bookkeeper.apply!(participant: participant_for(attacker), definitions: ability_effects[:buffs])
        end

        if ability_effects[:debuffs].present?
          effect_bookkeeper.apply!(participant: participant_for(defender), definitions: ability_effects[:debuffs])
        end
      end

      def combatant_snapshot(combatant)
        CombatantSnapshot.new(stats_with_effects(combatant))
      end

      def stats_with_effects(combatant)
        stats = combatant.respond_to?(:stats) ? combatant.stats : Game::Systems::StatBlock.new(base: {})
        return stats unless battle && effect_bookkeeper

        participant = participant_for(combatant)
        return stats unless participant

        stack = Game::Systems::EffectStack.new
        effect_bookkeeper.materialized_effects(participant).each { |effect| stack.add(effect) }
        stack.apply_to(stats)
        stats
      end

      def participant_for(combatant)
        return unless combatant.respond_to?(:id) && combatant.id

        participants_by_character[combatant.id]
      end

      def participants_by_character
        @participants_by_character ||= battle ? battle.battle_participants.index_by(&:character_id) : {}
      end

      def attacker_id
        attacker.respond_to?(:id) ? attacker.id : nil
      end

      def defender_id
        defender.respond_to?(:id) ? defender.id : nil
      end

      def parsed_ability_effects
        return empty_ability_effects unless ability&.effects.present?

        effects = ability.effects.deep_stringify_keys
        {
          damage_bonus: effects["damage"].to_i,
          buffs: Array.wrap(effects["buffs"]),
          debuffs: Array.wrap(effects["debuffs"]),
          status: effects["status"]
        }
      end

      def empty_ability_effects
        {damage_bonus: 0, buffs: [], debuffs: [], status: nil}
      end

      def effect_bookkeeper
        return unless battle

        @effect_bookkeeper ||= Game::Combat::EffectBookkeeper.new(battle:)
      end
    end
  end
end
