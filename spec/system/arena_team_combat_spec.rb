# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Synthetic 3x3 team combat", type: :system, js: true do
  let(:arena_room) do
    create(
      :arena_room,
      :trial,
      name: "Synthetic Browser Team Hall",
      level_min: 1,
      level_max: 100,
      max_concurrent_matches: 5
    )
  end

  before do
    @teams = %w[a b].index_with do |team|
      3.times.map do |index|
        user = create(
          :user,
          email: "browser-team-#{team}#{index + 1}@browser-rpg.test",
          profile_name: "browser_team_#{team}#{index + 1}"
        )
        character = create(
          :character,
          user:,
          name: "Browser#{team.upcase}#{index + 1}",
          level: 10,
          current_hp: 10_000,
          max_hp: 10_000,
          in_combat: true
        )
        create(:character_position, character:)
        {user:, character:}
      end
    end
    @match = create(
      :arena_match,
      :team_battle,
      :live,
      arena_room:,
      turn_timeout_seconds: 300
    )
    @participations = @teams.to_h do |team, players|
      [
        team,
        players.map do |player|
          create(
            :arena_participation,
            arena_match: @match,
            user: player.fetch(:user),
            character: player.fetch(:character),
            team:
          )
        end
      ]
    end
    page.current_window.resize_to(1280, 900)
  end

  it "switches a legal target, preserves waiting on reconnect, resolves all six turns once, and exposes result/log states" do
    side_a = @teams.fetch("a")
    side_b = @teams.fetch("b")
    players = side_a + side_b

    login(side_a.first)
    visit arena_match_path(@match)

    expect(page).to have_css(".arena-fighter--left .fighter-card", count: 3)
    expect(page).to have_css(".arena-fighter--right .fighter-card", count: 3)
    expect(page).to have_css("[data-arena-match-target='targetName']", text: "BrowserB1")
    expect(page).to have_button("Switch opponent", disabled: false)

    [[820, 900], [390, 844]].each do |width, height|
      page.current_window.resize_to(width, height)
      expect(page).to have_css(".fighter-card", count: 6)
      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const fight = document.querySelector(".arena-match-page")
          const main = document.querySelector(".nl-main-area")
          return fight.scrollWidth <= main.clientWidth + 1
        })()
      JS
    end
    page.current_window.resize_to(1280, 900)

    click_button "Switch opponent"

    expect(page).to have_css(".fighter-card--selected-target", text: "BrowserB2")
    expect(page).to have_css("[data-arena-match-target='targetName']", text: "BrowserB2")
    submit_physical_turn

    wait_for_pending_turn(side_a.first)
    visit arena_match_path(@match)
    expect(page).to have_content("Waiting for opponent turn")
    expect(page).to have_css("[data-arena-match-target='targetName']", text: "BrowserB2")
    page.refresh
    expect(page).to have_content("Waiting for opponent turn")
    expect(page).to have_css("[data-arena-match-target='targetName']", text: "BrowserB2")
    expect(@participations.fetch("a").first.reload.metadata.dig("pending_turn", "target_participation_id"))
      .to eq(@participations.fetch("b")[1].id)

    [side_a[1], side_a[2], side_b[0], side_b[1]].each do |player|
      login(player)
      visit arena_match_path(@match)
      submit_physical_turn
      wait_for_pending_turn(player)
      expect(@match.reload.current_turn_number).to eq(1)
    end

    login(side_b[2])
    visit arena_match_path(@match)
    submit_physical_turn

    wait_for_match_turn(2)
    expect(@match.reload.current_turn_number).to eq(2)
    visit arena_match_path(@match)
    expect(page).to have_css(".arena-match-page[data-arena-match-turn-number-value='2']")
    expect(page).to have_button("Turn")
    expect(@match.arena_participations.reload.map { |entry| entry.metadata["pending_turn"] }).to all(be_blank)
    expect(
      @match.combat_log_entries.where(log_type: "action").where("message LIKE ?", "%submitted a turn%").count
    ).to eq(6)

    expect(page).to have_button("Surrender")
    visit public_fight_log_path(@match)
    side_b.each do |player|
      result = Arena::CombatProcessor.new(@match).process_player_intent(
        player.fetch(:character),
        :surrender
      )
      expect(result).to be_success
    end
    expect(@match.reload).to be_completed

    login(side_b.last)
    visit arena_match_path(@match)
    expect(page).to have_css(".arena-result--defeat .arena-result-title", text: "Defeat")

    login(side_a.first)
    visit arena_match_path(@match)

    expect(page).to have_css(".arena-result--victory .arena-result-title", text: "Victory")
    expect(page).to have_css(".nl-fight-result-table tbody tr", count: 6)
    expect(page).to have_button("Finish Fight")
    players.each { |player| expect(page).to have_content(player.fetch(:character).name) }

    add_log_entries_until(51)
    visit public_fight_log_path(@match)

    expect(page).to have_css("body.nl-public-layout--fight-log")
    expect(page).not_to have_css("body.nl-game-layout")
    expect(page).to have_link("Statistics")
    expect(page).to have_link("2")
    players.each { |player| expect(page).to have_content(player.fetch(:character).name) }

    click_link "Statistics"
    expect(page).to have_css(".nl-fight-stat-table tbody tr", minimum: 6)
    expect(page).to have_link("Fight log")

    page.current_window.resize_to(390, 844)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth + 1")).to be(true)

    visit arena_match_path(@match)
    expect(page).to have_css(".nl-fight-result-table tbody tr", count: 6)
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const fight = document.querySelector(".arena-match-page")
        const main = document.querySelector(".nl-main-area")
        return fight.scrollWidth <= main.clientWidth + 1
      })()
    JS

    click_button "Finish Fight"
    expect(page).not_to have_current_path(arena_match_path(@match), wait: 10)
    expect(side_a.first.fetch(:character).reload).not_to be_in_combat
    expect(@participations.fetch("a").first.reload.metadata["finished_at"]).to be_present
  end

  it "keeps expired-wait timeout choices accessible for a 3x3 participant on desktop and mobile" do
    participation = @participations.fetch("a").first
    participation.update!(
      metadata: participation.metadata.to_h.merge(
        "pending_turn" => {
          "turn_number" => 1,
          "target_participation_id" => @participations.fetch("b").first.id,
          "attacks" => [{"action_key" => "simple", "body_part" => "torso"}],
          "blocks" => [{"action_key" => "head_block", "body_parts" => ["head"]}],
          "skills" => [],
          "total_ap" => 80
        }
      )
    )
    @match.update!(current_turn_started_at: 301.seconds.ago)

    login(@teams.fetch("a").first)
    visit arena_match_path(@match)

    expect(page).to have_content("Waiting for opponent turn")
    expect(page).to have_button("Timeout Victory")
    expect(page).to have_button("Accept Draw")

    page.current_window.resize_to(390, 844)
    expect(page).to have_css(".fighter-card", count: 6)
    expect(page).to have_button("Timeout Victory")
    expect(page).to have_button("Accept Draw")
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const fight = document.querySelector(".arena-match-page")
        const main = document.querySelector(".nl-main-area")
        return fight.scrollWidth <= main.clientWidth + 1
      })()
    JS
  end

  private

  def login(player)
    visit public_fight_log_path(@match)
    expect(page).to have_css("body.nl-public-layout--fight-log")
    logout(:user)
    login_as(player.fetch(:user), scope: :user)
  end

  def submit_physical_turn
    find("select[data-arena-match-target='attackSelect'][data-body-part='torso']")
      .find("option[value='simple']")
      .select_option
    find("select[data-arena-match-target='blockSelect'][data-body-part='head']")
      .find("option[value='head_block']")
      .select_option
    click_button "Turn"
  end

  def wait_for_pending_turn(player)
    participation = @match.arena_participations.find_by!(character: player.fetch(:character))

    page.document.synchronize do
      pending_turn = participation.reload.metadata["pending_turn"]
      raise Capybara::ExpectationNotMet, "pending turn was not persisted" if pending_turn.blank?

      pending_turn
    end
  end

  def wait_for_match_turn(turn_number)
    page.document.synchronize do
      current_turn = @match.reload.current_turn_number
      raise Capybara::ExpectationNotMet, "match did not reach turn #{turn_number}" unless current_turn == turn_number

      current_turn
    end
  end

  def add_log_entries_until(count)
    next_sequence = @match.combat_log_entries.maximum(:sequence).to_i + 1
    while @match.combat_log_entries.count < count
      create(
        :combat_log_entry,
        arena_match: @match,
        round_number: 2,
        sequence: next_sequence,
        log_type: "system",
        message: "Synthetic public-log boundary #{next_sequence}"
      )
      next_sequence += 1
    end
  end
end
