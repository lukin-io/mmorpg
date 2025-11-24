# frozen_string_literal: true

class TradeItemsController < ApplicationController
  def create
    trade_session = authorize TradeSession.find(params[:trade_session_id]), :update?
    trade_item = trade_session.trade_items.build(trade_item_params.merge(owner: current_user))
    if trade_item.save
      redirect_to trade_session_path(trade_session), notice: "Contribution added."
    else
      redirect_to trade_session_path(trade_session), alert: trade_item.errors.full_messages.to_sentence
    end
  end

  def destroy
    trade_item = TradeItem.find(params[:id])
    trade_session = trade_item.trade_session
    authorize trade_session, :update?
    unless trade_item.owner == current_user
      raise Pundit::NotAuthorizedError, "Cannot remove another player's contribution"
    end

    trade_item.destroy
    redirect_to trade_session_path(trade_session), notice: "Contribution removed."
  end

  private

  def trade_item_params
    params.require(:trade_item).permit(
      :item_name,
      :quantity,
      :item_quality,
      :currency_type,
      :currency_amount
    )
  end
end
