# frozen_string_literal: true

class PublicFightLogsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_device_identifier

  before_action :set_arena_match

  def show
    @view_mode = (params[:stat] == "1") ? :statistics : :log
    @page = (params[:p] || 1).to_i
    @per_page = 50
    @statistics = Combat::FightLogStatistics.new(@arena_match)
    @participants = @arena_match.arena_participations.includes(:character, :npc_template)
    @team_a = @participants.select { |participation| %w[a alpha].include?(participation.team) }
    @team_b = @participants.select { |participation| %w[b beta].include?(participation.team) }

    if @view_mode == :log
      @combat_log_entries = paginated_entries
      @total_pages = (@arena_match.combat_log_entries.count.to_f / @per_page).ceil
    end

    respond_to do |format|
      format.html
      format.json { render json: export_payload }
    end
  end

  private

  def set_arena_match
    @arena_match = ArenaMatch.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { render plain: "Fight log not found", status: :not_found }
      format.json { render json: {error: "fight log not found"}, status: :not_found }
    end
  end

  def paginated_entries
    offset = (@page - 1) * @per_page
    @arena_match.combat_log_entries
      .order(round_number: :asc, sequence: :asc)
      .offset(offset)
      .limit(@per_page)
  end

  def export_payload
    return @statistics.to_hash if @view_mode == :statistics

    {
      fight_id: @arena_match.id,
      status: @arena_match.status,
      pages: @total_pages,
      current_page: @page,
      public_path: public_fight_log_path(@arena_match),
      entries: @arena_match.combat_log_entries.order(:round_number, :sequence).map do |entry|
        Arena::CombatLogPresenter.row_for_entry(entry)
      end
    }
  end
end
