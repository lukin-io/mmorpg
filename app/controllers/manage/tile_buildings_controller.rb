# frozen_string_literal: true

module Manage
  class TileBuildingsController < ApplicationController
    before_action :set_tile_building, only: [:show, :edit, :update, :destroy]
    before_action :load_form_options, only: [:new, :create, :edit, :update]

    def index
      scope = TileBuilding.includes(:destination_zone).order(:zone, :y, :x)
      scope = scope.where(zone: params[:zone]) if params[:zone].present?
      @tile_buildings = paginate(scope)
      @zones = Zone.where(location_type: "outdoor").order(:name)
    end

    def show; end

    def new
      @tile_building = TileBuilding.new(building_type: "city", active: true, required_level: 1, metadata: {})
    end

    def edit; end

    def create
      @tile_building = TileBuilding.new
      attributes = parsed_tile_building_params

      if attributes && mutate(@tile_building, operation: :create, attributes:)
        redirect_to manage_tile_building_path(@tile_building), notice: "Cell building created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attributes = parsed_tile_building_params

      if attributes && mutate(@tile_building, operation: :update, attributes:)
        redirect_to manage_tile_building_path(@tile_building), notice: "Cell building updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if mutate(@tile_building, operation: :destroy)
        redirect_to manage_tile_buildings_path, notice: "Cell building deleted.", status: :see_other
      else
        redirect_to manage_tile_building_path(@tile_building), alert: @tile_building.errors.full_messages.to_sentence,
          status: :see_other
      end
    end

    private

    def set_tile_building
      @tile_building = TileBuilding.find(params[:id])
    end

    def parsed_tile_building_params
      parse_json_attributes(tile_building_params, @tile_building, :metadata)
    end

    def tile_building_params
      params.require(:tile_building).permit(
        :zone, :x, :y, :building_key, :building_type, :name, :destination_zone_id,
        :destination_x, :destination_y, :required_level, :active, :metadata
      )
    end

    def load_form_options
      @outdoor_zones = Zone.where(location_type: "outdoor").order(:name)
      @destination_zones = Zone.order(:location_type, :name)
    end
  end
end
