# frozen_string_literal: true

# Helpers for auction listing views.
module AuctionListingsHelper
  RARITY_ICONS = {
    "common" => "⚪",
    "uncommon" => "🟢",
    "rare" => "🔵",
    "epic" => "🟣",
    "legendary" => "🟠"
  }.freeze

  CURRENCY_ICONS = {
    "gold" => "🪙",
    "silver" => "🥈",
    "premium_tokens" => "💎"
  }.freeze

  def item_rarity_icon(listing)
    rarity = listing.item_metadata&.dig("rarity") || "common"
    RARITY_ICONS[rarity] || "⚪"
  end

  def currency_icon(currency_type)
    CURRENCY_ICONS[currency_type] || "💰"
  end

  def rarity_css_class(listing)
    rarity = listing.item_metadata&.dig("rarity") || "common"
    "rarity--#{rarity}"
  end
end
