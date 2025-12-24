# frozen_string_literal: true

module Game
  module Quests
    # RewardService applies the structured rewards stored on a quest when an
    # assignment is completed. It handles XP, currency, reputation, cosmetic
    # unlocks, profession unlocks, class abilities, housing upgrades, and
    # premium token fragments.
    #
    # Usage:
    #   Game::Quests::RewardService.new(assignment: assignment).claim!
    #
    # Returns:
    #   Result struct exposing the normalized reward payload that was applied.
    class RewardService
      class AlreadyClaimedError < StandardError; end
      Result = Struct.new(:assignment, :applied, keyword_init: true)

      def initialize(
        assignment:,
        experience_pipeline: Players::Progression::ExperiencePipeline,
        wallet_service: ::Economy::WalletService,
        inventory_expander: Game::Inventory::ExpansionService
      )
        @assignment = assignment
        @experience_pipeline_class = experience_pipeline
        @wallet_service_class = wallet_service
        @inventory_expander_class = inventory_expander
      end

      def claim!
        raise AlreadyClaimedError, "Rewards already claimed" if assignment.rewards_claimed?

        rewards = assignment.quest.rewards || {}
        applied = {}

        ApplicationRecord.transaction do
          applied[:xp] = grant_xp!(rewards)
          applied[:currency] = grant_currency!(rewards)
          applied[:reputation] = adjust_reputation!(rewards)
          applied[:recipes] = grant_recipes!(rewards)
          applied[:cosmetics] = grant_cosmetics!(rewards)
          applied[:premium_tokens] = grant_premium_tokens!(rewards)
          applied[:class_abilities] = unlock_class_abilities!(rewards)
          applied[:professions] = unlock_professions!(rewards)
          applied[:housing_upgrades] = grant_housing_upgrades!(rewards)

          assignment.update!(
            rewards_claimed_at: Time.current,
            metadata: assignment.metadata.merge("last_reward" => applied.compact)
          )
        end

        Result.new(assignment:, applied: applied.compact)
      end

      private

      attr_reader :assignment, :experience_pipeline_class, :wallet_service_class, :inventory_expander_class

      delegate :character, to: :assignment

      def rewards_hash(payload)
        payload.deep_stringify_keys
      end

      def grant_xp!(payload)
        xp_amount = rewards_hash(payload).fetch("xp", 0).to_i
        return 0 if xp_amount <= 0

        experience_pipeline_class.new(character:).grant!("quest" => xp_amount)
        xp_amount
      end

      def grant_currency!(payload)
        currencies = rewards_hash(payload)["currency"] || {}
        wallet = character.user.currency_wallet || character.user.create_currency_wallet!
        service = wallet_service_class.new(wallet:)

        currencies.each do |currency, amount|
          amt = amount.to_i
          next if amt.zero?

          service.adjust!(
            currency: currency,
            amount: amt,
            reason: "quest.reward",
            metadata: {quest_id: assignment.quest_id, assignment_id: assignment.id}
          )
        end

        currencies.presence || {}
      end

      def adjust_reputation!(payload)
        delta = rewards_hash(payload).fetch("reputation", 0).to_i
        return 0 if delta.zero?

        character.increment!(:reputation, delta)
        delta
      end

      def grant_recipes!(payload)
        recipe_keys = Array(rewards_hash(payload)["recipes"])
        return [] if recipe_keys.empty?

        metadata = character.metadata.deep_dup
        unlocked = Array(metadata.fetch("recipe_keys", []))
        metadata["recipe_keys"] = (unlocked + recipe_keys).uniq
        character.update!(metadata: metadata)
        recipe_keys
      end

      def grant_cosmetics!(payload)
        cosmetic_keys = Array(rewards_hash(payload)["cosmetics"])
        return [] if cosmetic_keys.empty?

        metadata = character.metadata.deep_dup
        unlocked = Array(metadata.fetch("cosmetic_keys", []))
        metadata["cosmetic_keys"] = (unlocked + cosmetic_keys).uniq
        character.update!(metadata: metadata)
        cosmetic_keys
      end

      def grant_premium_tokens!(payload)
        fragments = rewards_hash(payload).fetch("premium_tokens", 0).to_i
        return 0 if fragments.zero?

        wallet = character.user.currency_wallet || character.user.create_currency_wallet!
        wallet_service_class.new(wallet:).adjust!(
          currency: :premium_tokens,
          amount: fragments,
          reason: "quest.reward",
          metadata: {quest_id: assignment.quest_id}
        )
        fragments
      end

      def unlock_class_abilities!(payload)
        node_keys = Array(rewards_hash(payload)["class_abilities"])
        return [] if node_keys.empty?

        unlocked = []
        SkillNode.where(key: node_keys).find_each do |node|
          CharacterSkill.find_or_create_by!(character:, skill_node: node) do |record|
            record.unlocked_at = Time.current
          end
          unlocked << node.key
        end
        unlocked
      end

      def unlock_professions!(payload)
        profession_names = Array(rewards_hash(payload)["profession_unlocks"])
        return [] if profession_names.empty?

        unlocked = []
        Profession.where(name: profession_names).find_each do |profession|
          next if character.profession_progresses.exists?(profession:)

          progress = character.profession_progresses.create(
            profession:,
            user: character.user,
            skill_level: 1,
            experience: 0
          )
          unlocked << profession.name if progress.persisted?
        rescue ActiveRecord::RecordInvalid
          next
        end
        unlocked
      end

      def grant_housing_upgrades!(payload)
        count = rewards_hash(payload).fetch("housing_upgrades", 0).to_i
        return 0 if count <= 0

        expander = inventory_expander_class.new(character:)
        count.times do
          expander.expand!(source: :housing)
        rescue Pundit::NotAuthorizedError
          break
        end
        count
      end
    end
  end
end
