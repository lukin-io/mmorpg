# frozen_string_literal: true

require_relative "starter_wallet_grant"

admin = User.find_by(email: "first@lukin.io") || User.find_by(email: "admin@browser-rpg.test")
lukin_user = User.find_by(email: "second@lukin.io") || User.find_by(email: "lukin.maksim@gmail.com")

if defined?(CurrencyWallet)
  if admin
    Seeds::StarterWalletGrant.call(user: admin, amount: 7_500, metadata: {"source" => "starter_content"})
  end

  if lukin_user
    Seeds::StarterWalletGrant.call(user: lukin_user, amount: 4_200)
  end
end
