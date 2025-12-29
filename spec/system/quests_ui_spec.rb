# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Quests UI", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 1) }

  before do
    character
    login_as(user, scope: :user)
  end

  describe "success cases" do
    it "accepts, advances, and completes a quest via Turbo Frames" do
      quest = create(:quest, title: "A Call to Adventure", summary: "Begin your journey", min_level: 1)
      create(:quest_step,
        quest: quest,
        position: 1,
        content: {"dialogue" => "Will you help us?"},
        branching_outcomes: {
          "choices" => [{"key" => "accept", "label" => "I will help"}],
          "consequences" => {"accept" => {"result" => "continue"}}
        })
      create(:quest_step, quest: quest, position: 2, content: {"dialogue" => "Thank you, hero."})
      assignment = create(:quest_assignment, quest: quest, character: character, status: :pending)

      visit quests_path
      click_link "View Details", href: quest_path(quest)

      expect(page).to have_css("turbo-frame#quest-dialogue", text: "A Call to Adventure")

      within "turbo-frame#quest-dialogue" do
        click_button "Accept Quest"
        expect(page).to have_button("Mark Complete")
      end

      expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(assignment)}", text: "In progress")

      within "turbo-frame#quest-dialogue" do
        click_button "I will help"
        expect(page).to have_content("Thank you, hero.")

        click_button "Mark Complete"
        expect(page).to have_content("Quest status:")
        expect(page).to have_content("Completed")
      end
    end
  end

  describe "failure cases" do
    it "keeps the quest pending when requirements are not met" do
      quest = create(:quest, title: "High Level Quest", min_level: 5)
      assignment = create(:quest_assignment, quest: quest, character: character, status: :pending)

      visit quests_path
      click_link "View Details", href: quest_path(quest)

      within "turbo-frame#quest-dialogue" do
        click_button "Accept Quest"
      end

      expect(page).to have_css("#flash", text: "Requirements not met")
      expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(assignment)}", text: "Pending")
    end

    it "shows a validation error when advancing with an invalid branching choice" do
      quest = create(:quest, title: "Broken Branch")
      create(:quest_step,
        quest: quest,
        position: 1,
        content: {"dialogue" => "Choose wisely."},
        branching_outcomes: {
          "choices" => [{"key" => "missing_consequence", "label" => "Pick this"}]
        })
      create(:quest_assignment, quest: quest, character: character, status: :pending)

      visit quests_path
      click_link "View Details", href: quest_path(quest)

      within "turbo-frame#quest-dialogue" do
        click_button "Accept Quest"
        click_button "Pick this"
      end

      expect(page).to have_css("#flash", text: "Unknown choice")
    end
  end

  describe "null/edge cases" do
    it "renders a placeholder when a quest has no authored steps" do
      quest = create(:quest, title: "Empty Quest")
      create(:quest_assignment, quest: quest, character: character, status: :pending)

      visit quests_path
      click_link "View Details", href: quest_path(quest)

      expect(page).to have_css("turbo-frame#quest-dialogue", text: "No narrative steps authored yet")
    end
  end

  describe "authorization cases" do
    it "redirects unauthenticated users to login" do
      logout(:user)

      visit quests_path

      expect(page).to have_current_path(/sign_in/).or have_content("Log in")
    end
  end
end
