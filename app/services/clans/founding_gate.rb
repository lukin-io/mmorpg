# frozen_string_literal: true

module Clans
  # FoundingGate enforces the GDD rules for founding a clan:
  # - player must have a character at/above the configured level
  # - the founding quest must be completed
  # - the founder pays the gold fee up front
  #
  # Usage:
  #   Clans::FoundingGate.new(user:, character:, wallet:).enforce!(clan_name: "Elselands Vanguard")
  #
  # Returns:
  #   true once the fee is collected; raises RequirementError if conditions fail.
  class FoundingGate
    RequirementError = Class.new(StandardError)

    def initialize(user:, character:, wallet:, config: Rails.configuration.x.clans)
      @user = user
      @character = character
      @wallet = wallet
      @config = config
    end

    def enforce!(clan_name:)
      ensure_character!
      ensure_level!
      ensure_quest_completion!
      collect_fee!(clan_name)
      true
    end

    private

    attr_reader :user, :character, :wallet, :config

    def ensure_character!
      return if character.present?

      raise RequirementError, "Create a character before founding a clan."
    end

    def ensure_level!
      required = config.dig("founding", "required_level").to_i
      return if character.level >= required

      raise RequirementError, "Clan founders must reach level #{required}."
    end

    def ensure_quest_completion!
      quest_key = config.dig("founding", "quest_key")
      return if quest_key.blank?

      quest = Quest.find_by!(key: quest_key)
      assignment = QuestAssignment.find_by(quest:, character:)
      return if assignment&.completed?

      raise RequirementError, "Complete the #{quest.title} quest to inspire your clan."
    end

    def collect_fee!(clan_name)
      fee = config.dig("founding", "gold_fee").to_i
      if wallet.balance_for(:gold) < fee
        raise RequirementError, "Founding a clan costs #{fee} gold."
      end

      wallet.adjust!(
        currency: :gold,
        amount: -fee,
        reason: "clan.founding_fee",
        metadata: {clan_name:, founder_id: user.id}
      )
    end
  end
end
