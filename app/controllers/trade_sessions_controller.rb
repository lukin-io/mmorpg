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
    @preview = Trades::PreviewBuilder.new(trade_session: @trade_session).call
    @trade_item = TradeItem.new
  end

  def update
    trade_session = authorize TradeSession.find(params[:id])

    if params[:cancel].present?
      trade_session.update!(status: :cancelled, completed_at: Time.current)
      return redirect_to trade_session_path(trade_session), notice: "Trade cancelled."
    end

    if params[:confirm].present?
      trade_session = Trades::SessionManager
        .new(initiator: trade_session.initiator, recipient: trade_session.recipient)
        .confirm!(session: trade_session, actor: current_user)

      notice = trade_session.completed? ? "Trade completed." : "Trade confirmed."
      return redirect_to trade_session_path(trade_session), notice: notice
    end

    redirect_to trade_session_path(trade_session), alert: "Unknown trade action."
  end
end
