# frozen_string_literal: true

require "rails_helper"

RSpec.describe "combat/_battle.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:battle) do
    create(:battle,
      status: :active,
      combat_mode: "simultaneous",
      action_points_per_turn: 80,
      round_number: 1)
  end
  let(:player_participant) do
    create(:battle_participant,
      battle: battle,
      character: character,
      team: "alpha",
      is_alive: true,
      current_hp: 80,
      max_hp: 100,
      current_mp: 30,
      max_mp: 50)
  end
  let(:enemy_participant) do
    create(:battle_participant,
      battle: battle,
      character: nil,
      participant_type: "npc",
      team: "beta",
      is_alive: true,
      current_hp: 100,
      max_hp: 100)
  end

  before do
    assign(:battle, battle)
    assign(:player_participant, player_participant)
    assign(:enemy_participant, enemy_participant)
    assign(:available_attacks, [])
    assign(:available_blocks, [])
    assign(:available_skills, [])
    assign(:combat_log, [])
    assign(:can_act, true)
    assign(:team_alpha, [player_participant])
    assign(:team_beta, [enemy_participant])
  end

  it "renders the combat container" do
    render

    expect(rendered).to have_css(".nl-combat-container")
  end

  it "renders the turn-combat controller" do
    render

    expect(rendered).to have_css("[data-controller='turn-combat']")
  end

  it "renders action points display" do
    render

    expect(rendered).to have_css(".nl-action-points")
  end

  it "renders submit button when can act" do
    render

    expect(rendered).to have_button("Submit Turn")
  end

  it "renders reset button" do
    render

    expect(rendered).to have_button("Reset")
  end
end
