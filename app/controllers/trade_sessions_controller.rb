# frozen_string_literal: true

class TradeSessionsController < ApplicationController
  def create
    recipient = User.find(params[:recipient_id])
    authorize TradeSession

    session = Trades::SessionManager.new(initiator: current_user, recipient:).start!
    redirect_to trade_session_path(session), notice: "Trade started."
  end

  def show
    @trade_session = authorize TradeSession.find(params[:id])
    @trade_items = @trade_session.trade_items.includes(:owner)
  end

  def update
    trade_session = authorize TradeSession.find(params[:id])
    Trades::SessionManager.new(initiator: trade_session.initiator, recipient: trade_session.recipient).confirm!(session: trade_session, actor: current_user)
    redirect_to trade_session_path(trade_session), notice: "Trade updated."
  end
end
