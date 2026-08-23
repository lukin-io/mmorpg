# frozen_string_literal: true

require "rails_helper"

RSpec.describe "game_events/_game_event", type: :view do
  it "renders the timestamped fight result and emphasized experience" do
    event = build_stubbed(
      :game_event,
      :fight_finished,
      occurred_at: Time.zone.parse("2026-08-23 20:09:05")
    )

    render partial: "game_events/game_event", locals: {game_event: event}

    expect(rendered).to have_css(".game-event--fight-finished")
    expect(rendered).to have_css("time.game-event-time", text: "20:09:05")
    expect(rendered).to have_css(".game-event-system-label", text: "System information.")
    expect(rendered).to have_css(".game-event-combat-xp", text: "10")
  end

  it "renders an unbranded global marker and escapes announcement text" do
    event = build_stubbed(
      :game_event,
      :world_announcement,
      body: "Gate <script>alert(1)</script> opened"
    )

    render partial: "game_events/game_event", locals: {game_event: event}

    expect(rendered).to have_css(".game-event--global .game-event-source", text: "World")
    expect(rendered).to have_css(".game-event-attention", text: "Attention!")
    expect(rendered).not_to have_css("script")
    expect(rendered).to include("&lt;script&gt;")
    expect(rendered).not_to include("NeverLands.Ru")
  end

  it "renders a timestamped NV search result" do
    event = build_stubbed(
      :game_event,
      :money_found,
      occurred_at: Time.zone.parse("2026-08-23 21:52:17")
    )

    render partial: "game_events/game_event", locals: {game_event: event}

    expect(rendered).to have_css(".game-event--money-found")
    expect(rendered).to have_css("time.game-event-time", text: "21:52:17")
    expect(rendered).to have_css(".game-event-attention", text: "Attention!")
    expect(rendered).to have_css(".game-event-system-label", text: "System information.")
    expect(rendered).to have_css(".game-event-money", text: "24 NV")
  end
end
