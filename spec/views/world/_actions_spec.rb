# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_actions.html.erb", type: :view do
  let(:zone) { create(:zone, name: "Пепельный Берег", location_type: "outdoor") }
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

  it "explains the Neverlands wilderness fatigue lock" do
    assign(:movement_state, OpenStruct.new(locked_reason: :fatigued))

    render partial: "world/actions", locals: {available_actions: [], position:}

    expect(rendered).to have_css("[data-world-fatigue-lock='1']")
    expect(rendered).to have_content(I18n.t("game.world.actions_unavailable_title"))
  end

  it "explains the outdoor injury travel lock with an Inventory recovery link" do
    character = create(:character)
    allow(view).to receive(:current_character).and_return(character)
    assign(:movement_state, OpenStruct.new(locked_reason: :injured))

    render partial: "world/actions", locals: {available_actions: [], position:}

    expect(rendered).to have_css("[data-world-injury-lock='1']")
    expect(rendered).to have_content(I18n.t("game.injuries.outdoor_lock"))
    expect(rendered).to have_link(I18n.t("game.injuries.outdoor_lock_inventory"), href: inventory_path)
    expect(rendered).not_to have_css("[data-world-injury-obelisk='1']")
  end

  it "mentions Obelisk recall when bound during the outdoor injury lock" do
    character = create(:character)
    character.update!(
      metadata: character.metadata.to_h.merge(
        "ashen_obelisk" => {"zone_id" => position.zone_id, "x" => 1, "y" => 1, "zone_name" => "Coal"}
      )
    )
    allow(view).to receive(:current_character).and_return(character)
    assign(:movement_state, OpenStruct.new(locked_reason: :injured))

    render partial: "world/actions", locals: {available_actions: [], position:}

    expect(rendered).to have_css("[data-world-injury-obelisk='1']")
    expect(rendered).to have_content(I18n.t("game.injuries.outdoor_lock_obelisk"))
  end

  %w[drink fish].each do |action_type|
    it "keeps all authored local actions visible and disabled during #{action_type} without creating capabilities" do
      assign(:active_world_action, build(:world_action_offer, :accepted, action_type:, metadata: {"label" => action_type.capitalize}))
      assign(:tile_state, Game::World::TileStateResolver::Result.new(local_actions: [
        {"type" => "resource_search", "source_id" => "look"},
        {"type" => "fishing", "source_id" => "fis"},
        {"type" => "drinking", "source_id" => "dri"}
      ]))

      render partial: "world/actions", locals: {available_actions: [], position:}

      [I18n.t("game.world.local_action.resource_search.label"), I18n.t("game.world.local_action.fishing.label"), I18n.t("game.world.local_action.drinking.label")].each do |label|
        expect(rendered).to have_button(label, disabled: true, count: 1)
      end
      expect(rendered).not_to have_css("form, input[name='action_key']", visible: :all)
    end
  end

  it "retains the accepted action label if its authored declaration was removed during work" do
    assign(:active_world_action, build(:world_action_offer, :accepted, action_type: "drink", metadata: {"label" => I18n.t("game.world.local_action.drinking.label")}))
    assign(:tile_state, Game::World::TileStateResolver::Result.new(local_actions: []))

    render partial: "world/actions", locals: {available_actions: [], position:}

    expect(rendered).to have_button(I18n.t("game.world.local_action.drinking.label"), disabled: true, count: 1)
    expect(rendered).not_to have_css("form, input[name='action_key']", visible: :all)
  end

  it "does not reveal the hidden source-backed NPC encounter" do
    render partial: "world/actions", locals: {
      available_actions: [
        {
          type: :tile_npc,
          npc: {
            id: 1,
            npc_template_id: 2,
            alive: true,
            hostile: true,
            name: "Rat",
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

    expect(rendered).not_to have_button("Attack")
    expect(rendered).not_to include("Rat")
    expect(rendered).not_to have_css("input[name='action_key'][value='attack-action-key']", visible: :all)
  end

  it "renders source-backed building entry without generic structure labels" do
    render partial: "world/actions", locals: {
      available_actions: [
        {
          type: :tile_building,
          building: {
            id: 1,
            name: "Outpost Gate",
            destination: "Outpost",
            can_enter: true
          },
          offer: OpenStruct.new(action_key: "building-action-key")
        }
      ],
      position:
    }

    expect(rendered).to have_content("Outpost Gate")
    expect(rendered).to have_button("Enter")
    expect(rendered).to have_css("input[name='action_key'][value='building-action-key']", visible: :all)
    expect(rendered).not_to include("Structure Here")
  end


  it "renders a source-backed resource-search offer" do
    render partial: "world/actions", locals: {
      available_actions: [
        {
          type: :tile_local_action,
          local_action: {
            tile_id: 7,
            local_action_type: "resource_search",
            source_id: "look",
            label: I18n.t("game.world.local_action.resource_search.label"),
            description: "Search for herbs and local resources."
          },
          offer: OpenStruct.new(action_key: "resource-action-key")
        }
      ],
      position:
    }

    expect(rendered).to have_button(I18n.t("game.world.local_action.resource_search.label"))
    expect(rendered).to have_content("Search for herbs and local resources.")
    expect(rendered).to have_css("input[name='tile_id'][value='7']", visible: :all)
    expect(rendered).to have_css("input[name='local_action_type'][value='resource_search']", visible: :all)
    expect(rendered).to have_css("input[name='action_key'][value='resource-action-key']", visible: :all)
  end
end
