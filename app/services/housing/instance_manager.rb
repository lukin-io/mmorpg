# frozen_string_literal: true

module Housing
  # Manages creation and access rules for player housing plots.
  #
  # Usage:
  #   Housing::InstanceManager.new(user: user).ensure_default_plot!
  #   Housing::InstanceManager.new(plot: plot).update_access!(rules: {...})
  class InstanceManager
    def initialize(user: nil, plot: nil)
      @user = user
      @plot = plot || user&.housing_plots&.first
    end

    def ensure_default_plot!(plot_type: "apartment", location_key: "starter_city")
      raise ArgumentError, "User required" unless user

      user.housing_plots.first || user.housing_plots.create!(
        plot_type:,
        location_key:,
        storage_slots: 20,
        access_rules: {"visibility" => "friends"}
      )
    end

    def update_access!(rules:)
      plot.update!(access_rules: rules)
    end

    private

    attr_reader :user, :plot
  end
end

