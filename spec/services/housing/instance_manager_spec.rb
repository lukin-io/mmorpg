require "rails_helper"

RSpec.describe Housing::InstanceManager do
  it "creates default plot" do
    user = create(:user)

    manager = described_class.new(user:)
    plot = manager.ensure_default_plot!

    expect(plot).to be_persisted
    expect(user.housing_plots).to exist
  end
end
