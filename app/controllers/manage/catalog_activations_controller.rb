# frozen_string_literal: true

module Manage
  class CatalogActivationsController < ApplicationController
    def create
      authorize :manage, :access?
      load Rails.root.join("db/seeds/ashen_veil_item_catalog.rb")
      load Rails.root.join("db/seeds/ashen_veil_enemy_catalog.rb")
      load Rails.root.join("db/seeds/ashen_veil_runtime_activation.rb")
      redirect_to manage_idle_tick_path, notice: t("manage.catalog_activation.done")
    rescue StandardError => error
      redirect_to manage_idle_tick_path, alert: error.message
    end
  end
end
