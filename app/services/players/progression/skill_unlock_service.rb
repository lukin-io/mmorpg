# frozen_string_literal: true

module Players
  module Progression
    # SkillUnlockService enforces quest/level prerequisites when unlocking nodes from a class skill tree.
    #
    # Usage:
    #   Players::Progression::SkillUnlockService.new(character:, skill_node:).unlock!
    #
    # Returns:
    #   CharacterSkill record.
    class SkillUnlockService
      DEFAULT_COST = 1

      def initialize(character:, skill_node:)
        @character = character
        @skill_node = skill_node
      end

      def unlock!
        validate_prerequisites!

        CharacterSkill.transaction do
          character.decrement!(:skill_points_available, cost)
          CharacterSkill.create!(character:, skill_node:, unlocked_at: Time.current)
        end
      end

      private

      attr_reader :character, :skill_node

      def validate_prerequisites!
        raise Pundit::NotAuthorizedError, "Not enough skill points" if character.skill_points_available < cost
        raise Pundit::NotAuthorizedError, "Level too low" if level_required > character.level
        raise Pundit::NotAuthorizedError, "Quest requirement missing" if quest_required? && !quest_completed?
        missing_nodes = missing_prerequisite_node_keys
        raise Pundit::NotAuthorizedError, "Missing prerequisites: #{missing_nodes.join(", ")}" if missing_nodes.any?
      end

      def level_required
        requirements["level"].to_i
      end

      def quest_required?
        requirements.key?("quest")
      end

      def quest_completed?
        quest = Quest.find_by(key: requirements["quest"])
        return false unless quest

        QuestAssignment.exists?(quest:, character:, status: :completed)
      end

      def missing_prerequisite_node_keys
        required_keys = Array.wrap(requirements["nodes"])
        return [] if required_keys.empty?

        unlocked_keys = character.skill_nodes.where(skill_tree: skill_node.skill_tree).pluck(:key)
        required_keys - unlocked_keys
      end

      def cost
        requirements.fetch("skill_point_cost", DEFAULT_COST).to_i
      end

      def requirements
        skill_node.requirements || {}
      end
    end
  end
end
