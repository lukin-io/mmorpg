# frozen_string_literal: true

module Game
  module Combat
    class TurnResolver
      Result = Struct.new(:log, :hp_changes, :effects, :battle, keyword_init: true)

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
        damage = damage_formula.call(attacker, defender)
        crit_multiplier = crit_formula.call(attacker, defender)
        total_damage = (damage * crit_multiplier).to_i

        effects = Array.wrap(ability&.effects)
        log_line = "#{attacker.name} used #{action} for #{total_damage} damage"
        log_line += " (CRIT)" if crit_multiplier > 1
        log_entries = [log_line]

        if ability&.kind == "reaction"
          log_entries << "#{defender.name} suffered #{ability.effects['status']}" if ability.effects["status"]
        end

        persist_logs(log_entries, total_damage:, effects:)
        advance_battle_turn if battle

        Result.new(
          log: log_entries,
          hp_changes: {defender: -total_damage},
          effects: effects,
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
              defender: defender.name,
              action:,
              total_damage:,
              effects:
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
      end
    end
  end
end
