# frozen_string_literal: true

module Game
  module Systems
    class Effect
      attr_reader :name, :duration, :stat_changes

      def initialize(name:, duration:, stat_changes: {})
        @name = name
        @duration = duration
        @stat_changes = stat_changes
      end

      def tick!
        @duration -= 1
      end

      def expired?
        duration <= 0
      end
    end
  end
end
