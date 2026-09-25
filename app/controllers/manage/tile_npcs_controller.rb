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
      @tile_npc.assign_attributes(params.permit(:zone, :x, :y))
    end

    def edit; end

    def create
      @tile_npc = TileNpc.new
      attributes = parsed_tile_npc_params

      if attributes && mutate(@tile_npc, operation: :create, attributes:)
        sync_spawn_controls_to_template!(@tile_npc)
        redirect_to manage_tile_npc_path(@tile_npc), notice: I18n.t("manage.flashes.tile_npc_created"), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attributes = parsed_tile_npc_params

      if attributes && mutate(@tile_npc, operation: :update, attributes:)
        sync_spawn_controls_to_template!(@tile_npc)
        redirect_to manage_tile_npc_path(@tile_npc), notice: I18n.t("manage.flashes.tile_npc_updated"), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if mutate(@tile_npc, operation: :destroy)
        redirect_to manage_tile_npcs_path, notice: I18n.t("manage.flashes.tile_npc_deleted"), status: :see_other
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
      attributes = parse_json_attributes(tile_npc_params, @tile_npc, :metadata)
      Manage::TileNpcAttributes.new(attributes:, npc: @tile_npc).call if attributes
    end

    def tile_npc_params
      params.require(:tile_npc).permit(
        :zone, :x, :y, :npc_template_id, :npc_key, :npc_role, :level,
        :current_hp, :max_hp, :defeated_at, :respawns_at, :metadata, :active,
        :content_fields, :encounter_count, :respawn_seconds, :drop_chance_multiplier,
        rosters: [:key, :weight, :encounter_experience_reward, :trauma_percent,
          members: [:npc_key, :level, :level_min, :level_max, :hp]]
      )
    end

    def load_form_options
      @outdoor_zones = Zone.where(location_type: "outdoor").order(:name)
      @npc_templates = NpcTemplate.order(:name)
    end

    def sync_spawn_controls_to_template!(tile_npc)
      template = tile_npc.npc_template
      return unless template

      meta = template.metadata.to_h.deep_dup
      %w[respawn_seconds respawn_variance_seconds drop_chance_multiplier].each do |key|
        value = tile_npc.metadata.to_h[key]
        value.nil? ? meta.delete(key) : meta[key] = value
      end
      template.update!(metadata: meta) if meta != template.metadata.to_h
    end
  end
end
