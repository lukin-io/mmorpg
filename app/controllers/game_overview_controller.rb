# frozen_string_literal: true

# GameOverviewController exposes the public-facing landing page that mirrors the
# `doc/features/7_game_overview.md` specification and surfaces live KPIs.
class GameOverviewController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_device_identifier

  def show
    @presenter = GameOverview::OverviewPresenter.new

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "game_overview_metrics",
          partial: "game_overview/success_metrics_grid",
          locals: {presenter: @presenter}
        )
      end
    end
  end
end
