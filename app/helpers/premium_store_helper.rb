# frozen_string_literal: true

# Helpers for premium store views.
module PremiumStoreHelper
  CATEGORY_ICONS = {
    cosmetic: "🎨",
    mount: "🐎",
    pet: "🐾",
    boost: "⚡",
    convenience: "✨",
    storage: "📦",
    title: "👑"
  }.freeze

  def premium_item_icon(item)
    item[:icon] || CATEGORY_ICONS[item[:category].to_sym] || "💎"
  end

  def can_purchase?(item)
    current_user.premium_tokens_balance >= item[:price]
  end

  def already_owned?(item)
    return false unless item[:unique]

    Premium::ArtifactStore.user_owns?(current_user, item[:key])
  end
end
