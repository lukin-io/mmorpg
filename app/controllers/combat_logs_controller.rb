# frozen_string_literal: true

require "csv"

class CombatLogsController < ApplicationController
  before_action :set_battle

  def show
    authorize @battle
    @view_mode = params[:stat] == "1" ? :statistics : :log
    @page = (params[:p] || 1).to_i
    @per_page = 50

    if @view_mode == :statistics
      @statistics = Combat::StatisticsCalculator.new(@battle)
      @participants = @statistics.by_participant
      @element_breakdown = @statistics.element_breakdown
    else
      @combat_log_entries = paginated_entries
      @total_pages = (@battle.combat_log_entries.count.to_f / @per_page).ceil
    end

    @team_alpha = @battle.battle_participants.where(team: "alpha")
    @team_beta = @battle.battle_participants.where(team: "beta")
    @battle_ended = @battle.completed?

    respond_to do |format|
      format.html
      format.json { render json: export_payload }
      format.csv { send_data csv_export, filename: "battle-#{@battle.id}-logs.csv" }
    end
  end

  private

  def set_battle
    @battle = policy_scope(Battle).find(params[:id])
  end

  def paginated_entries
    scope = filtered_entries
    offset = (@page - 1) * @per_page
    scope.order(round_number: :asc, sequence: :asc).offset(offset).limit(@per_page)
  end

  def filtered_entries
    scope = @battle.combat_log_entries.includes(:ability)
    scope = scope.where(log_type: "attack") if params[:filter] == "damage"
    scope = scope.where("healing_amount > 0") if params[:filter] == "healing"
    scope = scope.where("? = ANY(tags)", params[:element]) if params[:element].present?
    scope = scope.where(actor_id: params[:actor_id]) if params[:actor_id].present?
    scope
  end

  def export_payload
    if @view_mode == :statistics
      @statistics.to_hash
    else
      {
        battle_id: @battle.id,
        pages: @total_pages,
        current_page: @page,
        entries: @battle.combat_log_entries.order(:round_number, :sequence).map do |entry|
          {
            round_number: entry.round_number,
            sequence: entry.sequence,
            log_type: entry.log_type,
            message: entry.message,
            damage_amount: entry.damage_amount,
            healing_amount: entry.healing_amount,
            tags: entry.tags,
            payload: entry.payload
          }
        end
      }
    end
  end

  def csv_export
    CSV.generate(headers: true) do |csv|
      csv << %w[round sequence type message damage healing tags]
      @battle.combat_log_entries.order(:round_number, :sequence).each do |entry|
        csv << [
          entry.round_number,
          entry.sequence,
          entry.log_type,
          entry.message,
          entry.damage_amount,
          entry.healing_amount,
          entry.tags.join(", ")
        ]
      end
    end
  end
end
