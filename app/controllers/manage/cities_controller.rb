# frozen_string_literal: true

module Manage
  class CitiesController < ApplicationController
    before_action :set_city, only: [:show, :edit, :update, :destroy]

    def index
      @cities = paginate(Zone.where(location_type: "city").order(:name))
    end

    def show; end

    def new
      @city = Zone.new(location_type: "city", width: 10, height: 10, metadata: {})
    end

    def edit; end

    def create
      @city = Zone.new(location_type: "city")
      attributes = parsed_city_params

      if attributes && mutate(@city, operation: :create, attributes: attributes.merge("location_type" => "city"))
        redirect_to manage_city_path(@city), notice: "City node created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      attributes = parsed_city_params

      if attributes && mutate(@city, operation: :update, attributes: attributes.merge("location_type" => "city"))
        redirect_to manage_city_path(@city), notice: "City node updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if mutate(@city, operation: :destroy)
        redirect_to manage_cities_path, notice: "City node deleted.", status: :see_other
      else
        redirect_to manage_city_path(@city), alert: @city.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_city
      @city = Zone.where(location_type: "city").find(params[:id])
    end

    def parsed_city_params
      parse_json_attributes(city_params, @city, :metadata)
    end

    def city_params
      params.require(:zone).permit(:name, :width, :height, :metadata)
    end
  end
end
