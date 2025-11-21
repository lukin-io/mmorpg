# frozen_string_literal: true

class GuildApplicationsController < ApplicationController
  def create
    guild = Guild.find(params[:guild_id])
    authorize guild, :apply?

    service = Guilds::ApplicationService.new(guild:, applicant: current_user)
    service.submit!(answers: application_params[:answers])

    redirect_to guild, notice: "Application submitted."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to guild, alert: e.message
  end

  def update
    application = authorize GuildApplication.find(params[:id])
    service = Guilds::ApplicationService.new(guild: application.guild, applicant: application.applicant)

    notice =
      if params[:decision] == "approve"
        service.approve!(reviewer: current_user)
        "Application approved."
      else
        service.reject!(reviewer: current_user, reason: application_params[:reason])
        "Application rejected."
      end

    redirect_to guild_path(application.guild), notice: notice
  end

  private

  def application_params
    permitted = params.require(:guild_application).permit(:reason, answers: {})
    answers = permitted[:answers]
    permitted[:answers] =
      case answers
      when ActionController::Parameters
        answers.to_unsafe_h
      when Hash
        answers
      else
        {"text" => answers}
      end
    permitted
  end
end
