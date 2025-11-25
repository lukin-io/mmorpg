# frozen_string_literal: true

require "csv"

class CombatLogsController < ApplicationController
  def show
    @battle = policy_scope(Battle).find(params[:id])
    authorize @battle
    @analytics = @battle.combat_analytics_report
    @combat_log_entries = filtered_entries

    respond_to do |format|
      format.html
      format.json { render json: export_payload(@combat_log_entries) }
      format.csv { send_data csv_export(@combat_log_entries), filename: "battle-#{@battle.id}-logs.csv" }
    end
  end

  private

  def filtered_entries
    scope = @battle.combat_log_entries.includes(:ability)
    scope = scope.damage if params[:filter] == "damage"
    scope = scope.healing if params[:filter] == "healing"
    scope = scope.by_actor(params[:actor_id]) if params[:actor_id].present?
    scope
  end

  def export_payload(entries)
    entries.map do |entry|
      entry.attributes.slice("round_number", "sequence", "message", "damage_amount", "healing_amount", "tags")
    end
  end

  def csv_export(entries)
    CSV.generate(headers: true) do |csv|
      csv << %w[round sequence message damage healing]
      entries.each do |entry|
        csv << [entry.round_number, entry.sequence, entry.message, entry.damage_amount, entry.healing_amount]
      end
    end
  end
end
