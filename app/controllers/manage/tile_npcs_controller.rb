# frozen_string_literal: true

module Manage
  class TileNpcsController < ApplicationController
    before_action :set_tile_npc, only: [:show, :edit, :update, :destroy]
    before_action :load_form_options, only: [:new, :create, :edit, :update]

    def index
      scope = TileNpc.includes(:npc_template).order(:zone, :y, :x)
      scope = scope.where(zone: params[:zone]) if params[:zone].present?
      @tile_npcs = paginate(scope)
      @zones = Zone.where(location_type: "outdoor").order(:name)
    end

    def show; end

    def new
      @tile_npc = TileNpc.new(npc_role: "hostile", level: 1, metadata: {"encounter_count" => 1})
    end

    def edit; end

    def create
      @tile_npc = TileNpc.new
      attributes = parsed_tile_npc_params

      if attributes && mutate(@tile_npc, operation: :create, attributes:)
        redirect_to manage_tile_npc_path(@tile_npc), notice: "Cell NPC created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attributes = parsed_tile_npc_params

      if attributes && mutate(@tile_npc, operation: :update, attributes:)
        redirect_to manage_tile_npc_path(@tile_npc), notice: "Cell NPC updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if mutate(@tile_npc, operation: :destroy)
        redirect_to manage_tile_npcs_path, notice: "Cell NPC deleted.", status: :see_other
      else
        redirect_to manage_tile_npc_path(@tile_npc), alert: @tile_npc.errors.full_messages.to_sentence,
          status: :see_other
      end
    end

    private

    def set_tile_npc
      @tile_npc = TileNpc.find(params[:id])
    end

    def parsed_tile_npc_params
      parse_json_attributes(tile_npc_params, @tile_npc, :metadata)
    end

    def tile_npc_params
      params.require(:tile_npc).permit(
        :zone, :x, :y, :npc_template_id, :npc_key, :npc_role, :level,
        :current_hp, :max_hp, :defeated_at, :respawns_at, :metadata
      )
    end

    def load_form_options
      @outdoor_zones = Zone.where(location_type: "outdoor").order(:name)
      @npc_templates = NpcTemplate.order(:name)
    end
  end
end
