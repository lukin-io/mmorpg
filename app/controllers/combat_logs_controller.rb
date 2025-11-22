# frozen_string_literal: true

class CombatLogsController < ApplicationController
  def show
    @battle = policy_scope(Battle).find(params[:id])
    authorize @battle
    @combat_log_entries = @battle.combat_log_entries.includes(:battle)
  end
end
