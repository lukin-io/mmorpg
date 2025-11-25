# frozen_string_literal: true

module Admin
  class ClanModerationsController < BaseController
    def index
      @clans = Clan.order(updated_at: :desc).limit(25)
      @recent_actions = ClanModerationAction.order(created_at: :desc).limit(25)
    end

    def create
      clan = Clan.find(params[:clan_id])
      service = Clans::Moderation::RollbackService.new(clan: clan, gm_user: current_user)

      case params[:operation]
      when "rollback"
        service.rollback!(log_entry_id: params[:log_entry_id])
        notice = "Rollback applied."
      when "dissolve"
        service.dissolve!(reason: params[:reason])
        notice = "Clan dissolved."
      else
        raise ArgumentError, "Unknown operation."
      end

      redirect_to admin_clan_moderations_path, notice: notice
    rescue => e
      redirect_to admin_clan_moderations_path, alert: e.message
    end
  end
end
