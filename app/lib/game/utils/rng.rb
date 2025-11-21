# frozen_string_literal: true

module Game
  module Utils
    class Rng
      attr_reader :seed

      def initialize(seed: 1)
        @seed = seed
      end

      def instance
        @instance ||= Random.new(seed)
      end
    end
  end
end
