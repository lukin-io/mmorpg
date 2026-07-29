# frozen_string_literal: true

module Manage
  class NpcTemplatesController < ApplicationController
    before_action :set_npc_template, only: [:show, :edit, :update, :destroy]

    def index
      scope = NpcTemplate.includes(:tile_npcs).order(:name)
      scope = scope.where(role: params[:role]) if params[:role].present?
      @npc_templates = paginate(scope)
    end

    def show; end

    def new
      @npc_template = NpcTemplate.new(role: "hostile", level: 1, dialogue: "...", metadata: {})
    end

    def edit; end

    def create
      @npc_template = NpcTemplate.new
      attributes = parsed_npc_template_params

      if attributes && mutate(@npc_template, operation: :create, attributes:)
        redirect_to manage_npc_template_path(@npc_template), notice: "NPC template created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attributes = parsed_npc_template_params

      if attributes && mutate(@npc_template, operation: :update, attributes:)
        redirect_to manage_npc_template_path(@npc_template), notice: "NPC template updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if mutate(@npc_template, operation: :destroy)
        redirect_to manage_npc_templates_path, notice: "NPC template deleted.", status: :see_other
      else
        redirect_to manage_npc_template_path(@npc_template), alert: @npc_template.errors.full_messages.to_sentence,
          status: :see_other
      end
    end

    private

    def set_npc_template
      @npc_template = NpcTemplate.find(params[:id])
    end

    def parsed_npc_template_params
      attributes = parse_json_attributes(npc_template_params, @npc_template, :metadata)
      return unless attributes

      attributes["role"] = attributes.delete("npc_role")
      attributes
    end

    def npc_template_params
      params.require(:npc_template).permit(:npc_key, :name, :npc_role, :level, :dialogue, :metadata)
    end
  end
end
