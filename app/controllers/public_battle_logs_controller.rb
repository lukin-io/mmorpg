# frozen_string_literal: true

# Public controller for shareable battle logs.
# No authentication required - battles are accessed via share token.
#
# @example Access a public battle log
#   GET /logs/:share_token
#   GET /logs/abc123def456
#
class PublicBattleLogsController < ApplicationController
  skip_before_action :authenticate_user!

  before_action :set_battle

  def show
    @view_mode = (params[:stat] == "1") ? :statistics : :log
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
    @is_public = true

    respond_to do |format|
      format.html { render "combat_logs/show" }
      format.json { render json: export_payload }
    end
  end

  private

  def set_battle
    @battle = Battle.find_by_share_token!(params[:share_token])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def paginated_entries
    offset = (@page - 1) * @per_page
    @battle.combat_log_entries
      .order(round_number: :asc, sequence: :asc)
      .offset(offset)
      .limit(@per_page)
  end

  def export_payload
    {
      battle_id: @battle.id,
      battle_type: @battle.battle_type,
      status: @battle.status,
      rounds: @battle.round_number,
      share_url: request.original_url,
      entries: @battle.combat_log_entries.order(:round_number, :sequence).map do |entry|
        {
          round_number: entry.round_number,
          sequence: entry.sequence,
          log_type: entry.log_type,
          message: entry.message,
          damage_amount: entry.damage_amount,
          healing_amount: entry.healing_amount,
          tags: entry.tags
        }
      end
    }
  end

  def render_not_found
    respond_to do |format|
      format.html do
        render html: <<~HTML.html_safe, status: :not_found, layout: "application"
          <div class="combat-log-viewer" style="text-align: center; padding: 60px 20px;">
            <h1 style="color: #d4af37; font-size: 48px;">⚔️</h1>
            <h2 style="color: #cc0000;">Battle Log Not Found</h2>
            <p style="color: #888;">This battle log does not exist or has been removed.</p>
            <p style="margin-top: 20px;">
              <a href="/" style="color: #d4af37;">← Return to Elselands</a>
            </p>
          </div>
        HTML
      end
      format.json { render json: {error: "Battle not found"}, status: :not_found }
    end
  end
end
