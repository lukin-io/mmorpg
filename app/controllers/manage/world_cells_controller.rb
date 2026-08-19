# frozen_string_literal: true

module Manage
  class WorldCellsController < ApplicationController
    before_action :set_world_cell, only: [:show, :edit, :update, :destroy]
    before_action :load_form_options, only: [:new, :create, :edit, :update]

    def index
      scope = MapTileTemplate.order(:zone, :y, :x)
      scope = scope.where(zone: params[:zone]) if params[:zone].present?
      @world_cells = paginate(scope)
      @zones = Zone.where(location_type: "outdoor").order(:name)
    end

    def show; end

    def new
      @world_cell = MapTileTemplate.new(terrain_type: "outdoor", passable: true, metadata: {})
    end

    def edit; end

    def create
      @world_cell = MapTileTemplate.new
      attributes = parsed_world_cell_params

      if attributes && mutate(@world_cell, operation: :create, attributes:)
        redirect_to manage_world_cell_path(@world_cell), notice: "World cell created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attributes = parsed_world_cell_params

      if attributes && mutate(@world_cell, operation: :update, attributes:)
        redirect_to manage_world_cell_path(@world_cell), notice: "World cell updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if mutate(@world_cell, operation: :destroy)
        redirect_to manage_world_cells_path, notice: "World cell deleted.", status: :see_other
      else
        redirect_to manage_world_cell_path(@world_cell), alert: @world_cell.errors.full_messages.to_sentence,
          status: :see_other
      end
    end

    private

    def set_world_cell
      @world_cell = MapTileTemplate.find(params[:id])
    end

    def parsed_world_cell_params
      parse_json_attributes(world_cell_params, @world_cell, :metadata)
    end

    def world_cell_params
      params.require(:map_tile_template).permit(:zone, :x, :y, :terrain_type, :passable, :metadata)
    end

    def load_form_options
      @outdoor_zones = Zone.where(location_type: "outdoor").order(:name)
    end
  end
end
