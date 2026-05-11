# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Economy & Group Loops", type: :system, js: true do
  describe "success cases" do
    it "places a bid on an auction listing" do
      seller = create(:user)
      bidder = create(:user)
      create(:character, user: bidder)
      listing = create(:auction_listing, seller: seller, item_name: "Iron Sword", starting_bid: 100, ends_at: 1.day.from_now, status: :active)

      login_as(bidder, scope: :user)
      visit auction_listing_path(listing)

      fill_in "Your Bid (Gold)", with: 101
      click_button "Place Bid"

      expect(page).to have_css("#flash", text: "Bid placed")
      expect(page).to have_content(bidder.profile_name)
    end

    it "runs a party invite and ready check flow" do
      leader = create(:user)
      invitee = create(:user)
      create(:character, user: leader)
      create(:character, user: invitee)

      login_as(leader, scope: :user)
      visit parties_path

      fill_in "Party Name", with: "Dungeon Prep"
      fill_in "Purpose", with: "Ready check"
      select "2", from: "Max Size"
      click_button "Create Party"

      expect(page).to have_css("#flash", text: "Party created")
      expect(page).to have_current_path(%r{/parties/\d+})
      party = Party.find(page.current_path.split("/").last)
      expect(page).to have_current_path(party_path(party))

      select invitee.profile_name, from: "Player"
      click_button "Send Invite"

      expect(page).to have_css("#flash", text: "Invitation sent")

      logout(:user)
      login_as(invitee, scope: :user)

      visit parties_path
      click_button "Accept"

      expect(page).to have_css("#flash", text: "Invitation accepted")
      expect(page).to have_content("Your Current Party")

      logout(:user)
      login_as(leader, scope: :user)

      visit party_path(party)
      click_button "Start Ready Check"

      expect(page).to have_css("#flash", text: "Ready check started")
      expect(page).to have_css("#ready_check_panel")

      click_button "I'm Ready!"
      expect(page).to have_css("#flash", text: "Ready state updated")

      logout(:user)
      login_as(invitee, scope: :user)

      visit party_path(party)
      click_button "I'm Ready!"

      expect(page).not_to have_css("#ready_check_panel")
    end

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
      click_button "Add to Trade"

      expect(page).to have_css("#flash", text: "Contribution added")
      expect(page).to have_content("Wolf Pelt")
    end
  end

  describe "failure cases" do
    it "rejects invalid auction bids" do
      seller = create(:user)
      bidder = create(:user)
      create(:character, user: bidder)
      listing = create(:auction_listing, seller: seller, item_name: "Iron Sword", starting_bid: 100, ends_at: 1.day.from_now, status: :active)

      login_as(bidder, scope: :user)
      visit auction_listing_path(listing)

      fill_in "Your Bid (Gold)", with: -5
      click_button "Place Bid"

      expect(page).to have_current_path(auction_listing_path(listing))
      expect(AuctionBid.where(auction_listing: listing).count).to eq(0)

      validation_message = page.evaluate_script("document.querySelector('input[name=\"auction_bid[amount]\"]').validationMessage")
      expect(validation_message).to match(/greater than or equal|at least/i)
    end

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

  describe "null/edge cases" do
    it "shows an expired notice for ended auctions" do
      seller = create(:user)
      bidder = create(:user)
      create(:character, user: bidder)
      listing = create(:auction_listing, seller: seller, item_name: "Old Sword", ends_at: 1.minute.ago, status: :active)

      login_as(bidder, scope: :user)
      visit auction_listing_path(listing)

      expect(page).to have_content("This auction has ended")
      expect(page).not_to have_button("Place Bid")
    end
  end

  describe "authorization cases" do
    it "blocks sellers from bidding on their own listing" do
      seller = create(:user)
      create(:character, user: seller)
      listing = create(:auction_listing, seller: seller, item_name: "Iron Sword", starting_bid: 100, ends_at: 1.day.from_now, status: :active)

      login_as(seller, scope: :user)
      visit auction_listing_path(listing)

      expect(page).to have_content("This is your listing")
      expect(page).not_to have_button("Place Bid")
    end

    it "redirects unauthenticated users to login" do
      listing = create(:auction_listing, item_name: "Iron Sword", starting_bid: 100, ends_at: 1.day.from_now, status: :active)

      visit auction_listing_path(listing)

      expect(page).to have_current_path(/sign_in/).or have_content("Log in")
    end
  end
end
