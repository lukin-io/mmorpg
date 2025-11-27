# frozen_string_literal: true

module Players
  module Progression
    # Handles unlocking skill nodes for characters.
    #
    # Validates prerequisites, skill point availability, and level requirements
    # before granting the skill.
    #
    # @example Unlock a skill
    #   service = SkillUnlockService.new(character: char, skill_node: node)
    #   service.unlock! # => true/false
    #
    class SkillUnlockService
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_reader :character, :skill_node

      def initialize(character:, skill_node:)
        @character = character
        @skill_node = skill_node
      end

      # Attempts to unlock the skill node for the character.
      #
      # @return [Boolean] true if successful
      # @raise [Pundit::NotAuthorizedError] when requirements are not met
      def unlock!
        unless valid_unlock?
          raise Pundit::NotAuthorizedError, errors.full_messages.first || "Cannot unlock skill"
        end

        CharacterSkill.transaction do
          CharacterSkill.create!(
            character: character,
            skill_node: skill_node,
            unlocked_at: Time.current
          )

          character.decrement!(:skill_points_available, skill_point_cost)

          # Grant any associated abilities
          ability_key = skill_node.effects&.fetch("ability_key", nil)
          grant_ability! if ability_key.present?

          # Broadcast achievement if first skill in tree
          check_tree_mastery!
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        errors.add(:base, e.message)
        false
      end

      private

      def valid_unlock?
        validate_not_already_unlocked &&
          validate_skill_points &&
          validate_level_requirement &&
          validate_prerequisites &&
          validate_quest_requirement &&
          validate_class_match
      end

      def validate_not_already_unlocked
        if character.character_skills.exists?(skill_node: skill_node)
          errors.add(:base, "Skill already unlocked")
          return false
        end
        true
      end

      def validate_skill_points
        cost = skill_point_cost
        available = character.skill_points_available || 0
        if available < cost
          errors.add(:base, "Not enough skill points (need #{cost}, have #{available})")
          return false
        end
        true
      end

      def skill_point_cost
        skill_node.resource_cost&.fetch("skill_points", 1) || 1
      end

      def validate_level_requirement
        required_level = skill_node.requirements&.fetch("level", 0) || 0
        if character.level < required_level
          errors.add(:base, "Level #{required_level} required")
          return false
        end
        true
      end

      def validate_prerequisites
        prereq_node_ids = skill_node.requirements&.fetch("prerequisite_node_ids", []) || []
        return true if prereq_node_ids.blank?

        unlocked_ids = character.character_skills.pluck(:skill_node_id)
        missing = prereq_node_ids - unlocked_ids

        if missing.any?
          prereq_names = SkillNode.where(id: missing).pluck(:name).join(", ")
          errors.add(:base, "Requires: #{prereq_names}")
          return false
        end
        true
      end

      def validate_quest_requirement
        quest_key = skill_node.requirements&.fetch("quest", nil)
        return true if quest_key.blank?

        unless character.quest_assignments.joins(:quest).exists?(quests: {key: quest_key}, status: :completed)
          errors.add(:base, "Required quest not completed: #{quest_key}")
          return false
        end
        true
      end

      def validate_class_match
        unless skill_node.skill_tree.character_class_id == character.character_class_id
          errors.add(:base, "Skill not available for your class")
          return false
        end
        true
      end

      def grant_ability!
        # Link the ability to the character's ability bar if applicable
        ability_key = skill_node.effects&.fetch("ability_key", nil)
        return unless ability_key

        ability = Ability.find_by(key: ability_key)
        return unless ability

        character.abilities << ability unless character.abilities.include?(ability)
      end

      def check_tree_mastery!
        tree = skill_node.skill_tree
        total_nodes = tree.skill_nodes.count
        unlocked_nodes = character.character_skills.joins(:skill_node).where(skill_nodes: {skill_tree_id: tree.id}).count

        return unless unlocked_nodes == total_nodes

        # Grant tree mastery achievement if Achievements::GrantService exists
        tree_key = tree.respond_to?(:key) ? tree.key : tree.id
        achievement = Achievement.find_by(key: "skill_tree_mastery_#{tree_key}")
        if achievement && defined?(Achievements::GrantService)
          Achievements::GrantService.new(character: character, achievement: achievement).grant!
        end
      end
    end
  end
end
