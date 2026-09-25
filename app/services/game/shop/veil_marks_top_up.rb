# frozen_string_literal: true

module Game
  module Shop
    # Free Veil Marks claim — blocked unless ALLOW_STUB_IAP=true.
    class VeilMarksTopUp
      Result = Struct.new(:success, :message, keyword_init: true)
      AMOUNT = 50
      COOLDOWN = 1.hour
      METADATA_KEY = "ashen_vm_topup_at"
      REASON = "ashen.sandbox_vm_topup"

      def initialize(character:, clock: -> { Time.current })
        @character = character
        @clock = clock
      end

      def call
        PremiumGateway.assert_stub_allowed!
        character.with_lock do
          character.reload
          if (wait = seconds_until_ready).positive?
            return failure(I18n.t("game.buildings.premium_topup_wait", minutes: (wait / 60.0).ceil))
          end

          wallet = character.user.currency_wallet ||
            character.user.create_currency_wallet!(nv_balance: 0, veil_marks: 0)
          wallet.adjust_veil_marks!(
            amount: AMOUNT,
            reason: REASON,
            metadata: {"character_id" => character.id}
          )
          character.update!(
            metadata: character.metadata.to_h.merge(METADATA_KEY => clock.call.iso8601(6))
          )
          Result.new(
            success: true,
            message: I18n.t("game.buildings.premium_topup_ok", amount: AMOUNT)
          )
        end
      rescue PremiumGateway::StubDisabled => error
        failure(error.message)
      end

      def seconds_until_ready
        return COOLDOWN.to_i unless PremiumGateway.stub_iap_allowed?

        stamp = character.metadata.to_h[METADATA_KEY]
        return 0 if stamp.blank?

        ready_at = Time.iso8601(stamp.to_s) + COOLDOWN
        [(ready_at - clock.call).ceil, 0].max
      rescue ArgumentError, TypeError
        0
      end

      def available?
        PremiumGateway.stub_iap_allowed? && seconds_until_ready <= 0
      end

      private

      attr_reader :character, :clock

      def failure(message)
        Result.new(success: false, message:)
      end
    end
  end
end
