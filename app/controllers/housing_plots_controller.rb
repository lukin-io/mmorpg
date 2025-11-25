# frozen_string_literal: true

class HousingPlotsController < ApplicationController
  before_action :set_plot, only: [:update, :upgrade, :decorate, :remove_decor]

  def index
    @housing_plots = policy_scope(HousingPlot).where(user: current_user).includes(:housing_decor_items, :visit_guild)
    @housing_plots.each { |plot| Housing::UpkeepService.new(plot: plot).collect! }
    @decor_item = HousingDecorItem.new
  end

  def create
    authorize HousingPlot
    manager = Housing::InstanceManager.new(user: current_user)
    manager.ensure_default_plot!(
      plot_type: housing_params[:plot_type],
      location_key: housing_params[:location_key],
      plot_tier: housing_params[:plot_tier] || "starter",
      exterior_style: housing_params[:exterior_style].presence || "classic",
      visit_scope: housing_params[:visit_scope] || "friends"
    )
    redirect_to housing_plots_path, notice: "Housing plot created."
  end

  def update
    authorize @plot
    Housing::InstanceManager.new(plot: @plot, user: current_user).update_access!(
      access_rules: normalized_access_rules,
      visit_scope: housing_params[:visit_scope],
      visit_guild: visit_guild_for_params,
      showcase_enabled: housing_params[:showcase_enabled]
    )
    redirect_to housing_plots_path, notice: "Housing preferences updated."
  end

  def upgrade
    authorize @plot, :update?
    Housing::InstanceManager.new(plot: @plot, user: current_user).upgrade_tier!(
      plot_tier: upgrade_params[:plot_tier],
      exterior_style: upgrade_params[:exterior_style]
    )
    redirect_to housing_plots_path, notice: "Housing tier upgraded."
  rescue Economy::WalletService::InsufficientFundsError
    redirect_to housing_plots_path, alert: "Insufficient funds for upgrade."
  end

  def decorate
    authorize @plot, :update?
    Housing::DecorPlacementService.new(plot: @plot, actor: current_user).place!(decor_params)
    redirect_to housing_plots_path, notice: "Décor placed."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to housing_plots_path, alert: e.record.errors.full_messages.to_sentence
  end

  def remove_decor
    authorize @plot, :update?
    decor = @plot.housing_decor_items.find(params[:decor_id])
    Housing::DecorPlacementService.new(plot: @plot, actor: current_user).remove!(decor)
    redirect_to housing_plots_path, notice: "Décor removed."
  end

  private

  def set_plot
    @plot = HousingPlot.find(params[:id])
  end

  def housing_params
    params.require(:housing_plot).permit(
      :plot_type,
      :location_key,
      :plot_tier,
      :exterior_style,
      :visit_scope,
      :visit_guild_id,
      :showcase_enabled,
      access_rules: {}
    )
  end

  def upgrade_params
    params.require(:upgrade).permit(:plot_tier, :exterior_style)
  end

  def decor_params
    attrs = params.require(:decor).permit(:name, :decor_type, :utility_slot, placement: {}, metadata: {})
    attrs[:placement] = parse_json_field(attrs[:placement])
    attrs[:metadata] = parse_json_field(attrs[:metadata])
    attrs
  end

  def visit_guild_for_params
    guild_id = housing_params[:visit_guild_id]
    return unless guild_id.present?

    current_user.guild_memberships.find_by(guild_id: guild_id)&.guild || Guild.find_by(id: guild_id)
  end

  def normalized_access_rules
    rules = housing_params[:access_rules]
    return rules.to_unsafe_h if rules.respond_to?(:to_unsafe_h)
    return rules if rules.is_a?(Hash)

    JSON.parse(rules.presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def parse_json_field(value)
    return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
    return {} if value.blank?

    JSON.parse(value)
  rescue JSON::ParserError
    {}
  end
end
