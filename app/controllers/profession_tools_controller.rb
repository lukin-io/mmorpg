# frozen_string_literal: true

class ProfessionToolsController < ApplicationController
  before_action :ensure_active_character!

  def repair
    tool = current_character.profession_tools.find(params[:id])
    authorize tool

    Professions::ToolMaintenance.new(
      tool: tool,
      inventory: current_character.inventory
    ).repair!(materials: tool.metadata.fetch("repair_materials", {}))

    redirect_to professions_path, notice: "#{tool.tool_type} repaired."
  rescue => e
    redirect_to professions_path, alert: e.message
  end
end
