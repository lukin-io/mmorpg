# frozen_string_literal: true

module Game
  module Shop
    # Single premium / Veil Marks gateway. Free stub IAP is hard-disabled unless
    # ALLOW_STUB_IAP is explicitly "true" (never default in production).
    module PremiumGateway
      module_function

      def stub_iap_allowed?
        ActiveModel::Type::Boolean.new.cast(ENV.fetch("ALLOW_STUB_IAP", "false"))
      end

      def assert_stub_allowed!
        return if stub_iap_allowed?

        raise StubDisabled, I18n.t("game.shop.stub_iap_disabled")
      end

      class StubDisabled < StandardError; end
    end
  end
end
