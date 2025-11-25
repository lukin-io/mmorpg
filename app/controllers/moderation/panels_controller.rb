# frozen_string_literal: true

module Moderation
  class PanelsController < ApplicationController
    def show
      authorize [:moderation, :panel]
      @panel = Moderation::PanelBuilder.new(user: current_user).call
    end
  end
end
