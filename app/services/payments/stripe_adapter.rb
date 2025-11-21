# frozen_string_literal: true

module Payments
  class StripeAdapter
    def initialize(client: Stripe)
      @client = client
    end

    def create_checkout_session(purchase)
      app_url = ENV.fetch("APP_URL", "http://localhost:3000")

      client::Checkout::Session.create(
        mode: "payment",
        customer_email: purchase.user.email,
        success_url: app_url,
        cancel_url: app_url,
        line_items: [
          {
            price_data: {
              currency: purchase.currency.downcase,
              unit_amount: purchase.amount_cents,
              product_data: { name: "Neverlands Premium Item" }
            },
            quantity: 1
          }
        ],
        metadata: purchase.metadata.merge(purchase_id: purchase.id)
      )
    end

    private

    attr_reader :client
  end
end
