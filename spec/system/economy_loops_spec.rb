# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Economy Loops", type: :system, js: true do
  def switch_to_user(user)
    Capybara.reset_sessions!
    Warden.test_reset!
    Warden.test_mode!
    login_as(user, scope: :user)
  end

  describe "success cases" do
    it "adds a trade contribution from the trade session UI" do
      initiator = create(:user)
      recipient = create(:user)
      initiator_character = create(:character, user: initiator)

      item_template = create(:item_template, name: "Wolf Pelt", item_type: "material", slot: "none", stat_modifiers: {})
      create(:inventory_item, inventory: initiator_character.inventory, item_template: item_template, quantity: 1)

      trade_session = create(:trade_session, initiator: initiator, recipient: recipient, status: :pending)

      login_as(initiator, scope: :user)
      visit trade_session_path(trade_session)

      select "Wolf Pelt (x1)", from: "Add Item"
      fill_in "Quantity", with: 1
      find_button("Add to Trade").scroll_to(:center).click

      expect(page).to have_css("#flash", text: "Contribution added")
      expect(page).to have_content("Wolf Pelt")
    end
  end

  describe "failure cases" do
    it "blocks trade session access for non-participants" do
      initiator = create(:user)
      recipient = create(:user)
      intruder = create(:user)
      create(:character, user: initiator)
      create(:character, user: intruder)

      trade_session = create(:trade_session, initiator: initiator, recipient: recipient, status: :pending)

      login_as(intruder, scope: :user)
      visit trade_session_path(trade_session)

      expect(page).to have_css("#flash", text: "not authorized")
    end
  end
end
