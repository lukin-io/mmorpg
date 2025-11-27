# frozen_string_literal: true

# Controller for arena betting (totalizator).
#
# Allows spectators to wager on match outcomes.
#
# @example Place a bet
#   POST /arena_matches/:arena_match_id/bets
#
class ArenaBetsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_arena_match
  before_action :set_bet, only: [:show, :destroy]

  # GET /arena_matches/:arena_match_id/bets
  def index
    @bets = @arena_match.arena_bets.includes(:user, :predicted_winner)
    @total_pool = ArenaBet.total_pool(@arena_match)
    @odds = calculate_odds
    @my_bet = @arena_match.arena_bets.find_by(user: current_user)
  end

  # POST /arena_matches/:arena_match_id/bets
  def create
    @bet = @arena_match.arena_bets.build(bet_params.merge(user: current_user))

    if @bet.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("betting_panel", partial: "arena_bets/betting_panel", locals: {match: @arena_match, my_bet: @bet}),
            turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :success, message: "Bet placed! Potential winnings: #{@bet.potential_winnings} gold"})
          ]
        end
        format.html { redirect_to arena_match_path(@arena_match), notice: "Bet placed successfully!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :alert, message: @bet.errors.full_messages.to_sentence})
        end
        format.html { redirect_to arena_match_path(@arena_match), alert: @bet.errors.full_messages.to_sentence }
      end
    end
  end

  # DELETE /arena_matches/:arena_match_id/bets/:id
  def destroy
    if @bet.pending? && @arena_match.pending?
      @bet.refund!
      redirect_to arena_match_path(@arena_match), notice: "Bet cancelled and refunded."
    else
      redirect_to arena_match_path(@arena_match), alert: "Cannot cancel bet after match has started."
    end
  end

  private

  def set_arena_match
    @arena_match = ArenaMatch.find(params[:arena_match_id])
  end

  def set_bet
    @bet = @arena_match.arena_bets.find(params[:id])
  end

  def bet_params
    params.require(:arena_bet).permit(:predicted_winner_id, :amount, :currency_type)
  end

  def calculate_odds
    @arena_match.arena_participations.map do |participation|
      {
        character: participation.character,
        odds: ArenaBet.odds_for(@arena_match, participation.character),
        pool: ArenaBet.pool_for_character(@arena_match, participation.character)
      }
    end
  end
end
