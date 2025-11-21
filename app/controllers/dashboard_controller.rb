# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    @feature_flags = Flipper.features
  end
end
