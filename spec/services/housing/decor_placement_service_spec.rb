require "rails_helper"

RSpec.describe Housing::DecorPlacementService do
  describe "#place!" do
    let(:plot) { create(:housing_plot, room_slots: 1) }
    let(:service) { described_class.new(plot:, actor: plot.user) }

    it "places décor when slots available" do
      expect do
        service.place!(name: "Forge", decor_type: :utility, placement: {x: 1, y: 1}, metadata: {"station" => "craft"})
      end.to change { plot.housing_decor_items.count }.by(1)
    end

    it "raises when exceeding trophy limit" do
      3.times { service.place!(name: "Trophy", decor_type: :trophy, placement: {x: 1, y: 1}, metadata: {}) }

      expect do
        service.place!(name: "Overflow", decor_type: :trophy, placement: {x: 0, y: 0}, metadata: {})
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
