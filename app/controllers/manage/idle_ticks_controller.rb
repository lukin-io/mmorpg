# frozen_string_literal: true

module Manage
  class IdleTicksController < ApplicationController
    def show
      authorize :manage, :access?
      @status = Game::Idle::ControlledTicker.new.status
    end

    def arm
      authorize :manage, :access?
      @status = Game::Idle::ControlledTicker.new.arm!(
        tick_ms: params[:tick_ms],
        batch: params[:batch]
      )
      IdleTickJob.perform_later
      redirect_to manage_idle_tick_path, notice: t("manage.idle_ticks.armed")
    end

    def disarm
      authorize :manage, :access?
      @status = Game::Idle::ControlledTicker.new.disarm!
      redirect_to manage_idle_tick_path, notice: t("manage.idle_ticks.disarmed")
    end

    def run_once
      authorize :manage, :access?
      @status = Game::Idle::ControlledTicker.new.run_once!(batch: params[:batch])
      redirect_to manage_idle_tick_path, notice: t("manage.idle_ticks.ran", ran: @status[:ran], errors: @status[:errors])
    end
  end
end
