# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World", type: :request do
  describe "Zone model schema" do
    # Regression test: Zone model should not have a description column
    # This covers the bug where city_view.html.erb tried to access zone.description
    # Fix: Use zone.metadata&.dig("description") instead

    it "does not have description column" do
      expect(Zone.column_names).not_to include("description")
    end

    it "has metadata column for storing description and other data" do
      expect(Zone.column_names).to include("metadata")
    end

    it "stores description in metadata JSONB" do
      zone = create(:zone, metadata: {"description" => "A test zone"})
      expect(zone.metadata["description"]).to eq("A test zone")
    end
  end
end
