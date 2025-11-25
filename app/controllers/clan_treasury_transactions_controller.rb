# frozen_string_literal: true

class ClanTreasuryTransactionsController < ApplicationController
  before_action :set_clan

  def create
    authorize @clan, :manage_treasury?

    membership = @clan.clan_memberships.find_by(user: current_user)
    service = Clans::TreasuryService.new(clan: @clan, actor: current_user, membership: membership)
    direction = treasury_params[:direction]
    amount = treasury_params[:amount].to_i
    currency = treasury_params[:currency_type].to_sym

    if direction == "deposit"
      service.deposit!(currency: currency, amount: amount, reason: treasury_params[:reason], metadata: {note: treasury_params[:note]})
    else
      service.withdraw!(currency: currency, amount: amount, reason: treasury_params[:reason], metadata: {note: treasury_params[:note]})
    end

    redirect_to clan_path(@clan), notice: "Treasury updated."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  private

  def set_clan
    @clan = Clan.find(params[:clan_id])
  end

  def treasury_params
    params.require(:clan_treasury_transaction).permit(:currency_type, :amount, :reason, :direction, :note)
  end
end
