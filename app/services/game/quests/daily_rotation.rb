# frozen_string_literal: true

module Game
  module Quests
    # DailyRotation selects a deterministic subset of daily quests per day/timebox.
    #
    # Usage:
    #   Game::Quests::DailyRotation.new(character: char).refresh!
    #
    # Returns:
    #   Hash describing active daily quests for the character.
    class DailyRotation
      ROTATION_SLOTS = %w[morning afternoon evening reset].freeze

      def initialize(character:, now: Time.current, assignment_class: QuestAssignment)
        @character = character
        @now = now
        @assignment_class = assignment_class
      end

      def refresh!
        Quest.daily.order(:sequence).each_with_index.each_with_object({}) do |(quest, index), memo|
          slot = quest.daily_reset_slot || ROTATION_SLOTS[index % ROTATION_SLOTS.length]
          assignment = assignment_class.find_or_initialize_by(quest:, character:)
          next if assignment.completed? && assignment.next_available_at.present? && assignment.next_available_at > now

          assignment.status = :pending
          assignment.next_available_at = next_reset_for(slot)
          assignment.expires_at = assignment.next_available_at
          assignment.save!
          memo[slot] ||= []
          memo[slot] << assignment
        end
      end

      private

      attr_reader :character, :now, :assignment_class

      def next_reset_for(slot)
        case slot
        when "morning" then now.beginning_of_day + 12.hours
        when "afternoon" then now.change(hour: 18)
        when "evening" then now.end_of_day
        else
          now.beginning_of_day + 1.day
        end
      end
    end
  end
end
