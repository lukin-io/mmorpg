# frozen_string_literal: true

class NpcReportsController < ApplicationController
  def new
    authorize NpcReport
    @report = NpcReport.new(npc_key: params[:npc_key])
    @npc = population_directory.npc(@report.npc_key) if @report.npc_key.present?
    @categories = NpcReport.categories.keys
  end

  def create
    authorize NpcReport
    report = Game::Moderation::NpcIntake.new.call(
      reporter: current_user,
      character: current_user.characters.first,
      npc_key: npc_report_params[:npc_key],
      category: npc_report_params[:category],
      description: npc_report_params[:description],
      evidence: npc_report_params.slice(:location, :screenshot_url, :chat_log_reference).compact_blank
    )

    redirect_to quests_path, notice: "Report submitted to #{report.npc_key.titleize}."
  rescue Game::Moderation::NpcIntake::InvalidNpc => e
    flash.now[:alert] = e.message
    new
    render :new, status: :unprocessable_entity
  end

  private

  def npc_report_params
    params.require(:npc_report).permit(:npc_key, :category, :description, :location, :screenshot_url, :chat_log_reference)
  end

  def population_directory
    Game::World::PopulationDirectory.instance
  end
end
