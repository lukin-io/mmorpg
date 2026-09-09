# frozen_string_literal: true

module Seeds
  # Credits a sample account's initial NV once, using the existing wallet writer.
  # The wallet lock spans the ledger lookup and credit; old seed.initial_nv
  # entries count as completion without rewriting balances or historical rows.
  # Returns the persisted wallet, including on a retry that needs no grant.
  class StarterWalletGrant
    REASON = "seed.initial_nv"
    GRANT_KEY = "starter_initial_nv_v1"

    def self.call(user:, amount:, metadata: {})
      wallet = CurrencyWallet.find_by(user:)
      unless wallet
        user.with_lock { wallet = CurrencyWallet.find_by(user:) || CurrencyWallet.create!(user:) }
      end
      wallet.with_lock do
        next wallet if wallet.currency_transactions.where(reason: REASON).exists?

        wallet.adjust!(amount:, reason: REASON, metadata: metadata.merge("seed_grant_key" => GRANT_KEY))
      end
    end
  end
end
