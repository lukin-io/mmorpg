# frozen_string_literal: true

module Game
  module Formulas
    class BaseFormula
      attr_reader :rng

      def initialize(rng: Random.new(1))
        @rng = rng
      end
    end
  end
end
