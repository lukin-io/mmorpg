# frozen_string_literal: true

module Game
  module Systems
    class TurnCycle
      attr_reader :turn_number

      def initialize
        @turn_number = 1
      end

      def next_turn!
        @turn_number += 1
      end
    end
  end
end
