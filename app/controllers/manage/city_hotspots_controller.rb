# frozen_string_literal: true

module Manage
  class CityHotspotsController < ApplicationController
    before_action :set_city_hotspot, only: [:show, :edit, :update, :destroy]
    before_action :load_form_options, only: [:new, :create, :edit, :update]

    def index
      scope = CityHotspot.includes(:zone, :destination_zone).order(:zone_id, :z_index, :key)
      scope = scope.where(zone_id: params[:zone_id]) if params[:zone_id].present?
      @city_hotspots = paginate(scope)
      @cities = Zone.where(location_type: "city").order(:name)
    end

    def show; end

    def new
      @city_hotspot = CityHotspot.new(
        hotspot_type: "building", action_type: "open_feature", required_level: 0,
        active: true, z_index: 0, action_params: {}
      )
    end

    def edit; end

    def create
      @city_hotspot = CityHotspot.new
      attributes = parsed_city_hotspot_params

      if attributes && mutate(@city_hotspot, operation: :create, attributes:)
        redirect_to manage_city_hotspot_path(@city_hotspot), notice: "City action created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attributes = parsed_city_hotspot_params

      if attributes && mutate(@city_hotspot, operation: :update, attributes:)
        redirect_to manage_city_hotspot_path(@city_hotspot), notice: "City action updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if mutate(@city_hotspot, operation: :destroy)
        redirect_to manage_city_hotspots_path, notice: "City action deleted.", status: :see_other
      else
        redirect_to manage_city_hotspot_path(@city_hotspot), alert: @city_hotspot.errors.full_messages.to_sentence,
          status: :see_other
      end
    end

    private

    def set_city_hotspot
      @city_hotspot = CityHotspot.find(params[:id])
    end

    def parsed_city_hotspot_params
      parse_json_attributes(city_hotspot_params, @city_hotspot, :action_params)
    end

    def city_hotspot_params
      params.require(:city_hotspot).permit(
        :zone_id, :key, :name, :hotspot_type, :position_x, :position_y,
        :width, :height, :action_type, :destination_zone_id, :action_params,
        :required_level, :z_index, :active
      )
    end

    def load_form_options
      @cities = Zone.where(location_type: "city").order(:name)
      @destination_zones = Zone.order(:location_type, :name)
    end
  end
end
