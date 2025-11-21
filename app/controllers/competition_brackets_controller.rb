# frozen_string_literal: true

class CompetitionBracketsController < ApplicationController
  def show
    @competition_bracket = authorize CompetitionBracket.find(params[:id])
    @matches = @competition_bracket.competition_matches.order(round_number: :asc)
  end

  def update
    bracket = authorize CompetitionBracket.find(params[:id])
    bracket.update!(status: params[:status]) if params[:status].present?
    redirect_to competition_bracket_path(bracket), notice: "Bracket updated."
  end
end

