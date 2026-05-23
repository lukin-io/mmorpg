# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_actions.html.erb", type: :view do
  let(:zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor") }
  let(:position) { create(:character_position, zone:, x: 5, y: 5) }
  let(:offer) { OpenStruct.new(action_key: "attack-action-key") }

  it "does not render a generic direction pad for map movement offers" do
    render partial: "world/actions", locals: {
      available_actions: [{type: :move, destinations: []}],
      position:
    }

    expect(rendered).not_to have_css(".direction-btn")
    expect(rendered).not_to include("North")
    expect(rendered).not_to include("Move")
  end

  it "does not render duplicate moving-state text outside the map timer" do
    render partial: "world/actions", locals: {
      available_actions: [{type: :moving, remaining_seconds: 17}],
      position:
    }

    expect(rendered).not_to include("Moving")
    expect(rendered).not_to have_css(".movement-cooldown")
  end

  it "renders source-backed NPC fight action without generic creature labels" do
    render partial: "world/actions", locals: {
      available_actions: [
        {
          type: :tile_npc,
          npc: {
            id: 1,
            npc_template_id: 2,
            alive: true,
            hostile: true,
            name: "Крыса",
            level: 1,
            hp: 10,
            max_hp: 10,
            hp_percentage: 100
          },
          offer:
        }
      ],
      position:
    }

    expect(rendered).to have_button("Напасть")
    expect(rendered).to have_css("input[name='action_key'][value='attack-action-key']", visible: :all)
    expect(rendered).not_to include("Creature Here")
    expect(rendered).not_to include("Attack")
  end

  it "renders source-backed building entry without generic structure labels" do
    render partial: "world/actions", locals: {
      available_actions: [
        {
          type: :tile_building,
          building: {
            id: 1,
            name: "Ворота Форпоста",
            icon: ">",
            building_type: "city_gate",
            destination: "Форпост",
            can_enter: true
          },
          offer: OpenStruct.new(action_key: "building-action-key")
        }
      ],
      position:
    }

    expect(rendered).to have_content("Ворота Форпоста")
    expect(rendered).to have_button("Войти")
    expect(rendered).to have_css("input[name='action_key'][value='building-action-key']", visible: :all)
    expect(rendered).not_to include("Structure Here")
    expect(rendered).not_to include("Enter")
  end
end
