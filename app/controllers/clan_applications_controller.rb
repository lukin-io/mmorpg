# frozen_string_literal: true

class ClanApplicationsController < ApplicationController
  before_action :set_clan
  before_action :ensure_active_character!, only: :create

  def create
    authorize @clan

    service = Clans::ApplicationPipeline.new(clan: @clan, actor: current_user)
    service.submit!(
      answers: application_params.fetch(:vetting_answers, {}),
      character: current_character,
      referral: referral_user
    )

    redirect_to clan_path(@clan), notice: "Application submitted."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to clan_path(@clan), alert: e.record.errors.full_messages.to_sentence
  end

  def update
    authorize @clan, :manage_recruitment?
    application = @clan.clan_applications.find(params[:id])

    Clans::ApplicationPipeline.new(clan: @clan, actor: current_user).review!(
      application: application,
      reviewer: current_user,
      decision: application_params[:decision],
      reason: application_params[:decision_reason]
    )

    redirect_to clan_path(@clan), notice: "Application updated."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  private

  def set_clan
    @clan = Clan.find(params[:clan_id])
  end

  def application_params
    params.require(:clan_application).permit(:decision, :decision_reason, :referral_user_id, vetting_answers: {})
  end

  def referral_user
    User.find_by(id: application_params[:referral_user_id])
  end
end
