# frozen_string_literal: true

module Players
  module Progression
    # Handles skill respec (reset) for characters.
    #
    # Supports free respec (quest token) or paid respec (gold/premium).
    #
    # @example Respec skills via quest
    #   service = RespecService.new(character: char, source: :quest, quest_key: "respec_ritual")
    #   service.call! # => true/false
    #
    # @example Respec skills via premium tokens
    #   service = RespecService.new(character: char, source: :premium, premium_cost: 25)
    #   service.call! # => true/false
    #
    class RespecService
      include ActiveModel::Model
      include ActiveModel::Validations

      RESPEC_GOLD_COST = 1000
      RESPEC_COOLDOWN_HOURS = 24

      attr_reader :character, :source, :quest_key, :premium_cost, :payment_method

      def initialize(character:, source: :gold, quest_key: nil, premium_cost: nil, payment_method: nil)
        @character = character
        @source = source
        @quest_key = quest_key
        @premium_cost = premium_cost || 25
        @payment_method = payment_method || source
      end

      # Resets all skill points and stats, refunding them to the character.
      #
      # @return [Boolean] true if successful
      def call!
        respec!
      end

      # Resets all skill points and stats, refunding them to the character.
      #
      # @return [Boolean] true if successful
      def respec!
        return false unless valid_respec?

        CharacterSkill.transaction do
          # Calculate refunded skill points (from resource_cost jsonb or default 1)
          refunded_skill_points = character.character_skills.sum do |cs|
            cs.skill_node.resource_cost&.fetch("skill_points", 1) || 1
          end

          # Calculate refunded stat points
          refunded_stat_points = character.allocated_stats&.values&.sum.to_i

          # Remove all skills
          character.character_skills.destroy_all

          # Remove granted abilities (from skill unlocks)
          remove_skill_granted_abilities!

          # Refund skill points
          character.increment!(:skill_points_available, refunded_skill_points) if refunded_skill_points.positive?

          # Refund stat points
          character.increment!(:stat_points_available, refunded_stat_points) if refunded_stat_points.positive?

          # Clear allocated stats
          character.update!(allocated_stats: {})

          # Charge cost
          charge_respec_cost!

          # Set cooldown
          character.update!(last_respec_at: Time.current) if character.respond_to?(:last_respec_at)
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        errors.add(:base, e.message)
        false
      end

      private

      def valid_respec?
        validate_has_skills_or_stats &&
          validate_cooldown &&
          validate_payment
      end

      def validate_has_skills_or_stats
        has_skills = character.character_skills.any?
        has_stats = character.allocated_stats.present? && character.allocated_stats.values.sum.positive?

        unless has_skills || has_stats
          errors.add(:base, "No skills or stats to reset")
          return false
        end
        true
      end

      def validate_cooldown
        return true unless character.respond_to?(:last_respec_at)
        return true if character.last_respec_at.nil?

        hours_since = ((Time.current - character.last_respec_at) / 1.hour).to_i
        if hours_since < RESPEC_COOLDOWN_HOURS
          remaining = RESPEC_COOLDOWN_HOURS - hours_since
          errors.add(:base, "Respec available in #{remaining} hours")
          return false
        end
        true
      end

      def validate_payment
        case source.to_sym
        when :gold
          if character.respond_to?(:gold) && character.gold < RESPEC_GOLD_COST
            errors.add(:base, "Need #{RESPEC_GOLD_COST} gold (have #{character.gold})")
            return false
          end
        when :premium
          if character.user.premium_tokens_balance < premium_cost
            errors.add(:base, "Need #{premium_cost} premium tokens")
            return false
          end
        when :quest
          unless quest_completed?
            errors.add(:base, "Required quest not completed")
            return false
          end
        when :quest_token
          unless character.respond_to?(:has_respec_token?) && character.has_respec_token?
            errors.add(:base, "No respec token available")
            return false
          end
        end
        true
      end

      def quest_completed?
        return false unless quest_key

        character.quest_assignments.joins(:quest).exists?(quests: {key: quest_key}, status: :completed)
      end

      def charge_respec_cost!
        case source.to_sym
        when :gold
          character.decrement!(:gold, RESPEC_GOLD_COST) if character.respond_to?(:gold)
        when :premium
          Payments::PremiumTokenLedger.debit(
            user: character.user,
            amount: premium_cost,
            reason: "Skill Respec",
            actor: character.user
          )
        when :quest
          # Quest completion is the payment, nothing to charge
        when :quest_token
          character.consume_respec_token! if character.respond_to?(:consume_respec_token!)
        end
      end

      def remove_skill_granted_abilities!
        return unless character.respond_to?(:abilities)

        ability_keys = character.character_skills.includes(:skill_node).filter_map do |character_skill|
          character_skill.skill_node.effects&.fetch("ability_key", nil)
        end.compact.uniq

        return if ability_keys.empty?

        abilities = Ability.where(key: ability_keys)
        character.abilities.delete(abilities)
      end
    end
  end
end
