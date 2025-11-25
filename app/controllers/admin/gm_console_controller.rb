# frozen_string_literal: true

module Admin
  class GmConsoleController < BaseController
    before_action :authorize_console

    def show
      @quests = Quest.order(:title)
      @snapshots = QuestAnalyticsSnapshot.recent.limit(20)
    end

    def spawn
      gm_service.spawn_assignment!(**spawn_params)
      redirect_to admin_gm_console_path, notice: "Quest assignment spawned."
    rescue ActiveRecord::RecordNotFound, Game::Quests::GmConsoleService::OperationError => e
      redirect_to admin_gm_console_path, alert: e.message
    end

    def disable
      gm_service.disable_quest!(**disable_params)
      redirect_to admin_gm_console_path, notice: "Quest disabled."
    rescue ActiveRecord::RecordNotFound => e
      redirect_to admin_gm_console_path, alert: e.message
    end

    def adjust_timers
      gm_service.adjust_timers!(**adjust_params)
      redirect_to admin_gm_console_path, notice: "Timers adjusted."
    rescue ActiveRecord::RecordNotFound => e
      redirect_to admin_gm_console_path, alert: e.message
    end

    def compensate
      gm_service.compensate_players!(**compensate_params)
      redirect_to admin_gm_console_path, notice: "Compensation sent."
    rescue ActiveRecord::RecordNotFound, Game::Quests::GmConsoleService::OperationError => e
      redirect_to admin_gm_console_path, alert: e.message
    end

    private

    def authorize_console
      raise Pundit::NotAuthorizedError unless current_user&.has_any_role?(:gm, :admin)
    end

    def gm_service
      @gm_service ||= Game::Quests::GmConsoleService.new(actor: current_user)
    end

    def spawn_params
      params.require(:gm).permit(:quest_key, :character_id).to_h.symbolize_keys
    end

    def disable_params
      params.require(:gm).permit(:quest_key, :reason).to_h.symbolize_keys
    end

    def adjust_params
      params.require(:gm).permit(:quest_key, :minutes).to_h.symbolize_keys
    end

    def compensate_params
      params.require(:gm).permit(:quest_key, :currency, :amount).to_h.symbolize_keys
    end
  end
end
