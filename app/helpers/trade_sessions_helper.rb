# frozen_string_literal: true

# Helpers for trade session views.
module TradeSessionsHelper
  def trade_partner(trade_session)
    (trade_session.initiator == current_user) ? trade_session.recipient : trade_session.initiator
  end

  def trade_confirmed_by_you?(trade_session)
    if trade_session.initiator == current_user
      trade_session.initiator_confirmed?
    else
      trade_session.recipient_confirmed?
    end
  end

  def trade_item_icon(item)
    return currency_icon_for(item) if item.currency?

    item_type = item.item_metadata&.dig("item_type") || ItemTemplate.find_by(name: item.item_name)&.item_type

    case item_type
    when "equipment"
      "⚔️"
    when "consumable"
      "🧪"
    when "material"
      "📦"
    else
      "📄"
    end
  end

  def currency_icon_for(item)
    case item.currency_type
    when "gold"
      "🪙"
    when "silver"
      "🥈"
    when "premium_tokens"
      "⭐"
    else
      "🪙"
    end
  end

  def inventory_items_for_select(user)
    return [] unless user.character

    user.character.inventory&.inventory_items&.map do |item|
      ["#{item.item_template.name} (x#{item.quantity})", item.item_template.name]
    end || []
  end
end
