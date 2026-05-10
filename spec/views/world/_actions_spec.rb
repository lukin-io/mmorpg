# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_actions.html.erb", type: :view do
  let(:zone) { create(:zone, name: "Action Plains", biome: "plains") }
  let(:position) { create(:character_position, zone:, x: 5, y: 5) }
  let(:north_offer) do
    OpenStruct.new(direction: "north", target_x: 5, target_y: 4, action_key: "north-action-key")
  end
  let(:east_offer) do
    OpenStruct.new(direction: "east", target_x: 6, target_y: 5, action_key: "east-action-key")
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:move_world_path).and_return("/world/move")
    end
  end

  it "renders movement buttons with server-issued target coordinates and action keys" do
    render partial: "world/actions", locals: {
      available_actions: [{type: :move, destinations: [north_offer, east_offer]}],
      position:
    }

    expect(rendered).to have_css("form[action='/world/move']", count: 2)
    expect(rendered).to have_css("input[name='direction'][value='north']", visible: :all)
    expect(rendered).to have_css("input[name='target_x'][value='5']", visible: :all)
    expect(rendered).to have_css("input[name='target_y'][value='4']", visible: :all)
    expect(rendered).to have_css("input[name='action_key'][value='north-action-key']", visible: :all)
    expect(rendered).to have_css("input[name='direction'][value='east']", visible: :all)
    expect(rendered).to have_css("input[name='action_key'][value='east-action-key']", visible: :all)
  end

  it "renders disabled directions when the server did not offer them" do
    render partial: "world/actions", locals: {
      available_actions: [{type: :move, destinations: [north_offer]}],
      position:
    }

    expect(rendered).to have_css(".direction-btn--north")
    expect(rendered).to have_css(".direction-btn--disabled", minimum: 3)
    expect(rendered).not_to have_css("input[name='action_key'][value='east-action-key']", visible: :all)
  end

  it "shows the moving state instead of movement forms during travel" do
    render partial: "world/actions", locals: {
      available_actions: [{type: :moving, remaining_seconds: 17}],
      position:
    }

    expect(rendered).to include("Moving... 17s")
    expect(rendered).not_to have_css("form[action='/world/move']")
  end
end
