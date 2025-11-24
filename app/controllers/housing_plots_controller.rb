# frozen_string_literal: true

class HousingPlotsController < ApplicationController
  def index
    @housing_plots = policy_scope(HousingPlot).where(user: current_user)
    @housing_plots.each { |plot| Housing::UpkeepService.new(plot: plot).collect! }
  end

  def create
    authorize HousingPlot
    manager = Housing::InstanceManager.new(user: current_user)
    manager.ensure_default_plot!(plot_type: housing_params[:plot_type], location_key: housing_params[:location_key])
    redirect_to housing_plots_path, notice: "Housing plot created."
  end

  def update
    plot = authorize HousingPlot.find(params[:id])
    Housing::InstanceManager.new(plot:).update_access!(rules: housing_params[:access_rules] || {})
    redirect_to housing_plots_path, notice: "Access updated."
  end

  private

  def housing_params
    params.require(:housing_plot).permit(:plot_type, :location_key, access_rules: {})
  end
end
