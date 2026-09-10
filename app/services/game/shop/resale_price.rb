# frozen_string_literal: true

module Game
  module Shop
    # Pure merchant resale calculation. Trading is profession proficiency, not
    # an allocatable passive skill. The quoted payout includes durability wear;
    # fixed-decimal NV is rounded once after applying both factors.
    class ResalePrice
      RATES = [[600, 70], [475, 60], [350, 50], [225, 40], [100, 30], [0, 20]].freeze

      def initialize(base_price:, trading_skill: 0, current_durability: nil, max_durability: nil)
        @base_price = base_price.to_d
        @trading_skill = trading_skill.to_i
        @current_durability = current_durability&.to_d
        @max_durability = max_durability&.to_d
      end

      def percent
        RATES.find { |minimum, _rate| trading_skill >= minimum }&.last || 20
      end

      def amount
        return BigDecimal("0") unless base_price.positive?

        value = base_price * percent / 100
        if max_durability&.positive?
          return BigDecimal("0") unless current_durability&.between?(0, max_durability)

          value *= current_durability / max_durability
        end
        value.round(2)
      end

      private

      attr_reader :base_price, :trading_skill, :current_durability, :max_durability
    end
  end
end
