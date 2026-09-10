# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City Shop purchase", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }

  before do
    allow($stdout).to receive(:puts)
    Rails.application.load_seed
    @city = Zone.find_by!(name: "Outpost")
    @position = create(:character_position, character:, zone: @city, x: 0, y: 0)
    user.currency_wallet.update!(nv_balance: 100)
    @penknife = ItemTemplate.find_by!(key: "penknife")
    @shop_account = ShopAccount.find_by!(location: CityHotspot.find_by!(zone: @city, key: "shop"))
    @penknife_stock = @shop_account.shop_stocks.find_by!(item_template: @penknife)
    @inventory = character.inventory || character.create_inventory!
  end

  after do
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  def set_viewport(width, height)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width:, height:, deviceScaleFactor: 1, mobile: false)
  end

  def sign_in_through_form
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"
  end

  def penknife_row
    find(".nl-shop-table > tbody > tr", text: "Penknife")
  end

  def loaded_penknife_artwork(image)
    expect(image[:src]).to include("/assets/items/penknife")
    expect(page.evaluate_async_script(<<~JS, image)).to be(true)
      const image = arguments[0];
      const done = arguments[arguments.length - 1];
      image.decode().then(() => done(image.naturalWidth > 0)).catch(() => done(false));
    JS
    image[:src]
  end

  def displayed_armor_pierce
    find(".nl-sheet-table--chips tr", text: "Armor pierce").find("td").text.delete_suffix("%").to_d
  end

  def enter_market_from_shop
    within(".nl-top-nav") { click_link "City" }
    expect(page).to have_css(".nl-city-scene[aria-label='Central Square city map']")
    within(".city-actions") { click_button "Residential Quarter" }
    expect(page).to have_css(".nl-city-scene[aria-label='Residential Quarter city map']")
    within(".city-actions") { click_button "Market" }
    expect(page).to have_css(".nl-city-building-page[data-building-key='market']")
  end

  def enter_shop_from_market
    within(".nl-city-building-header") { click_link "City" }
    expect(page).to have_css(".nl-city-scene[aria-label='Residential Quarter city map']")
    within(".city-actions") { click_button "Central Square" }
    expect(page).to have_css(".nl-city-scene[aria-label='Central Square city map']")
    within(".city-actions") { click_button "Shop" }
    expect(page).to have_css(".nl-shop-page")
    within(".nl-shop-tabs") { click_link "Licenses" }
  end

  it "confirms a single purchase and restores its inventory and Shop context after login" do
    set_viewport(1500, 1000)
    sign_in_through_form
    expect(page).to have_css(".nl-city-scene")
    within(".city-actions") { click_button "Shop" }
    expect(page).to have_css(".nl-shop-page")
    expect(page).to have_css(".nl-shop-category", count: 19)
    expect(page).not_to have_field("quantity")
    original_stock = @penknife_stock.current
    original_weight = @inventory.current_weight
    original_items = @inventory.inventory_items.count

    dismiss_confirm("Buy Penknife?") { within(penknife_row) { click_button "Buy" } }
    expect(user.currency_wallet.reload.balance).to eq(100)
    expect(@penknife_stock.reload.current).to eq(original_stock)
    expect(@inventory.inventory_items.count).to eq(original_items)

    accept_confirm("Buy Penknife?") { within(penknife_row) { click_button "Buy" } }
    expect(penknife_row).to have_content("(quantity: #{original_stock - 1} / 500)")
    expect(user.currency_wallet.reload.balance).to eq(93)
    expect(@inventory.reload.current_weight).to eq(original_weight + 5)
    expect(@inventory.inventory_items.count).to eq(original_items + 1)
    bought = @inventory.inventory_items.find_by!(item_template: @penknife)
    expect(bought).to have_attributes(quantity: 1, current_durability: 10, max_durability: 10)

    within(".nl-top-nav") { click_button "Inventory" }
    expect(page).to have_css(".nl-inventory-page")
    expect(page).to have_content("Penknife")
    expect(page).to have_content("10/10")
    # The shared Inventory action keeps the saved Shop as its parent frame.
    # Reload restores Shop; reopening Inventory reads the persisted item.
    page.refresh
    expect(page).to have_css(".nl-shop-page")
    within(".nl-top-nav") { click_button "Inventory" }
    expect(page).to have_css(".nl-inventory-page")
    expect(page).to have_content("Penknife")
    expect(page).to have_content("10/10")

    accept_confirm("Exit the game?") { find("a[href='#{destroy_user_session_path}']").click }
    expect(page).to have_current_path(new_user_session_path, wait: 10)
    sign_in_through_form
    expect(page).to have_css(".nl-shop-page")
    expect(page).to have_css(".nl-shop-category[aria-label='Knives'][aria-current='page']")
    expect(penknife_row).to have_content("(quantity: #{original_stock - 1} / 500)")
    expect(@inventory.inventory_items.find_by!(id: bought.id)).to have_attributes(quantity: 1, current_durability: 10)
    expect(user.currency_wallet.reload.balance).to eq(93)

    within(".nl-top-nav") { click_link "City" }
    expect(page).to have_css(".nl-city-scene")
    expect(@position.reload).to have_attributes(zone: @city, x: 0, y: 0)
  end

  it "qualifies as a Merchant, buys a license and goods, wears and removes the item, then restores Shop stock by selling it" do
    character.update!(perks: {"merchant" => true})
    user.currency_wallet.update!(nv_balance: 1_500)
    license_template = ItemTemplate.find_by!(key: "trading_license_i")
    license_stock = @shop_account.shop_stocks.find_by!(item_template: license_template)
    original_license_stock = license_stock.current
    original_knife_stock = @penknife_stock.current
    original_shop_balance = @shop_account.nv_balance
    original_mass = @inventory.current_weight
    original_item_count = @inventory.inventory_items.count
    login_as(user, scope: :user)
    set_viewport(1500, 1000)
    visit shop_path(mode: "licenses")

    expect(find(".nl-shop-license[aria-label='Trading License I']")).to have_button("Buy", disabled: true)
    expect(find(".nl-shop-license[aria-label='Trading License I'] input", visible: :all)[:title]).to eq("Merchant qualification required.")
    enter_market_from_shop
    click_button "Accept Merchant qualification"
    expect(page).to have_content("Collect the receipt from the Shop for 1,000 NV, then return here.")
    enter_shop_from_market
    page.execute_script("document.querySelector('.nl-shop-frame').scrollIntoView({block: 'start'})")
    page.save_screenshot(Rails.root.join("tmp/shop-merchant-qualification-desktop.png"))
    click_button "Pay 1,000 NV and collect receipt"
    expect(page).to have_content("Receipt received. Return to the Market.")
    expect(user.currency_wallet.reload.balance).to eq(500)
    expect(@shop_account.reload.nv_balance).to eq(original_shop_balance + 1_000)
    expect(@inventory.reload.current_weight).to eq(original_mass)
    expect(@inventory.inventory_items.count).to eq(original_item_count)
    expect(find(".nl-shop-license[aria-label='Trading License I']")).to have_button("Buy", disabled: true)
    enter_market_from_shop
    click_button "Complete Merchant qualification"
    expect(page).to have_content("Merchant qualification completed. Trading licenses are available in the Shop.")
    expect(character.reload.metadata.dig("profession_unlocks", "merchant")).to be(true)
    enter_shop_from_market
    original_shop_balance = @shop_account.reload.nv_balance

    expect(page).to have_css(".nl-shop-license", count: 6)
    expect(page).to have_css("img.nl-shop-license__artwork", count: 6)
    expect(page.evaluate_async_script(<<~JS)).to be(true)
      const done = arguments[arguments.length - 1];
      const images = [...document.querySelectorAll("img.nl-shop-license__artwork")];
      Promise.all(images.map(image => image.decode())).then(() =>
        done(images.every(image => image.naturalWidth === 384))).catch(() => done(false));
    JS
    expect(page).not_to have_css(".nl-shop-categories, .nl-shop-filters")
    card = find(".nl-shop-license[aria-label='Trading License I']")
    expect(card).to have_button("Buy")
    page.execute_script("document.querySelector('.nl-shop-frame').scrollIntoView({block: 'start'})")
    page.save_screenshot(Rails.root.join("tmp/shop-licenses-desktop.png"))
    set_viewport(390, 844)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth + 1")).to be(true)
    expect(page.evaluate_script("document.querySelector('.nl-shop-table-viewport').scrollWidth > document.querySelector('.nl-shop-table-viewport').clientWidth")).to be(true)
    page.execute_script("document.querySelector('.nl-shop-frame').scrollIntoView({block: 'start'})")
    page.save_screenshot(Rails.root.join("tmp/shop-licenses-mobile.png"))
    set_viewport(1500, 1000)

    accept_confirm("Buy Trading License I?") { within(card) { click_button "Buy" } }
    expect(page).to have_css(".nl-shop-license[aria-label='Trading License I'] .nl-shop-license__stock", text: /Stock:\s*#{original_license_stock - 1}/)
    grant = character.character_licenses.find_by!(kind: "trading")
    expect(grant.expires_at - grant.starts_at).to eq(3.days)
    expect(user.currency_wallet.reload.balance).to eq(200)
    expect(@shop_account.reload.nv_balance).to eq(original_shop_balance + 300)
    expect(@inventory.reload.current_weight).to eq(original_mass)
    expect(@inventory.inventory_items.count).to eq(original_item_count)

    find("a[aria-label='Abilities']").click
    expect(page).to have_content("Your licenses")
    expect(page).to have_css("#character_license_#{grant.id}", text: "Trading License I")
    expect(page).to have_css("#character_license_#{grant.id} time[datetime='#{grant.expires_at.iso8601}']")
    page.refresh
    expect(page).to have_css("#character_license_#{grant.id}", text: "Trading License I")

    visit shop_path
    artwork_src = loaded_penknife_artwork(penknife_row.find("img.nl-shop-item-icon"))
    accept_confirm("Buy Penknife?") { within(penknife_row) { click_button "Buy" } }
    expect(penknife_row).to have_content("(quantity: #{original_knife_stock - 1} / 500)")
    expect(user.currency_wallet.reload.balance).to eq(193)
    item = @inventory.inventory_items.find_by!(item_template: @penknife)

    within(".nl-top-nav") { click_button "Inventory" }
    expect(page).to have_css(".nl-inventory-page")
    inventory_image = find(".nl-inventory-item[data-item-id='#{item.id}'] img.nl-inventory-item-artwork")
    expect(loaded_penknife_artwork(inventory_image)).to eq(artwork_src)
    original_armor_pierce = character.reload.armor_pierce_percent
    within(".nl-inventory-item[data-item-id='#{item.id}']") { click_button "Wear" }
    expect(page).to have_css("button[aria-label='Remove Penknife from Weapon']")
    expect(page).not_to have_css(".nl-inventory-item[data-item-id='#{item.id}']")
    expect(item.reload).to have_attributes(equipped: true, equipment_slot: "main_hand")
    expect(character.reload.armor_pierce_percent).to eq(original_armor_pierce + 1)
    expect(displayed_armor_pierce).to eq(original_armor_pierce + 1)
    equipped_image = find(".nl-doll-slot--main_hand img[alt='Penknife']")
    expect(loaded_penknife_artwork(equipped_image)).to eq(artwork_src)

    page.refresh
    expect(page).to have_css(".nl-shop-page")
    within(".nl-top-nav") { click_button "Inventory" }
    expect(page).to have_css("button[aria-label='Remove Penknife from Weapon']")
    expect(displayed_armor_pierce).to eq(original_armor_pierce + 1)
    find("button[aria-label='Remove Penknife from Weapon']").click
    expect(page).to have_css(".nl-inventory-item[data-item-id='#{item.id}']")
    expect(page).not_to have_css("button[aria-label='Remove Penknife from Weapon']")
    expect(item.reload).to have_attributes(equipped: false, equipment_slot: nil)
    expect(character.reload.armor_pierce_percent).to eq(original_armor_pierce)
    expect(displayed_armor_pierce).to eq(original_armor_pierce)
    inventory_image = find(".nl-inventory-item[data-item-id='#{item.id}'] img.nl-inventory-item-artwork")
    expect(loaded_penknife_artwork(inventory_image)).to eq(artwork_src)
    page.refresh
    expect(page).to have_css(".nl-shop-page")

    within(".nl-shop-tabs") { click_link "Sell Goods" }
    expect(penknife_row).to have_button("Sell for 1.4 NV")
    expect(loaded_penknife_artwork(penknife_row.find("img.nl-shop-item-icon"))).to eq(artwork_src)
    accept_confirm("Sell Penknife?") { within(penknife_row) { click_button "Sell for 1.4 NV" } }

    expect(page).to have_content("There are no sellable items in inventory.")
    expect(@inventory.inventory_items.exists?(item.id)).to be(false)
    expect(@inventory.reload.current_weight).to eq(original_mass)
    expect(user.currency_wallet.reload.balance).to eq(BigDecimal("194.40"))
    expect(@shop_account.reload.nv_balance).to eq(original_shop_balance + BigDecimal("305.60"))
    expect(@penknife_stock.reload.current).to eq(original_knife_stock)
    expect(license_stock.reload.current).to eq(original_license_stock - 1)
    page.refresh
    expect(page).to have_content("There are no sellable items in inventory.")
    expect(character.character_licenses.active_at(Time.current)).to include(grant)
  end

  def expect_entrance_geometry
    expect(page).to have_css(".nl-building-entrance[style*='--nl-entrance-height']")
    page.evaluate_async_script(<<~JS)
      const done = arguments[arguments.length - 1];
      requestAnimationFrame(() => requestAnimationFrame(done));
    JS
    geometry = page.evaluate_script(<<~JS)
      (() => {
        const main = document.querySelector(".nl-main-area")
        const top = document.querySelector(".nl-top-bar")
        const image = document.querySelector(".nl-building-entrance__image")
        const desiredHeight = Math.min(600, Math.max(300, (main.clientHeight + top.offsetHeight) * 0.75))
        const expectedWidth = Math.min(main.clientWidth, desiredHeight * 1250 / 600)
        const rect = image.getBoundingClientRect()
        const tabs = document.querySelector(".nl-shop-tabs").getBoundingClientRect()
        return {width: rect.width, height: rect.height, expectedWidth,
          expectedHeight: expectedWidth * 600 / 1250, gap: tabs.top - rect.bottom}
      })()
    JS
    expect(geometry.fetch("width")).to be_within(1).of(geometry.fetch("expectedWidth"))
    expect(geometry.fetch("height")).to be_within(1).of(geometry.fetch("expectedHeight"))
    expect(geometry.fetch("gap")).to be_within(1).of(4)
  end

  it "scales the entrance with the gameplay pane and keeps compact controls inside local overflow" do
    login_as(user, scope: :user)
    set_viewport(1500, 1000)
    visit shop_path
    expect(page).to have_css(".nl-shop-category", count: 19)
    expect(penknife_row).to have_button("Buy")
    expect(page).to have_css(".nl-shop-tabs a", count: 4)
    expect(page).not_to have_css(".nl-shop-controls, .nl-shop-topline, .nl-shop-category__label")
    expect(page).to have_css(".nl-shop-category[title='Knives']")
    top_gap = page.evaluate_script(<<~JS)
      document.querySelector(".nl-building-entrance__image").getBoundingClientRect().top -
        document.querySelector(".nl-top-bar").getBoundingClientRect().bottom
    JS
    expect(top_gap).to be_within(1).of(10)
    expect_entrance_geometry
    set_viewport(1500, 640)
    expect_entrance_geometry
    set_viewport(1500, 1200)
    expect_entrance_geometry
    set_viewport(1500, 1000)
    expect_entrance_geometry
    artwork_geometry = page.evaluate_script(<<~JS)
      (() => {
        const cell = document.querySelector(".nl-shop-icon-cell").getBoundingClientRect()
        const image = document.querySelector(".nl-shop-item-icon").getBoundingClientRect()
        return {column: cell.width, width: image.width, height: image.height}
      })()
    JS
    expect(artwork_geometry).to eq("column" => 69, "width" => 62, "height" => 91)
    page.save_screenshot(Rails.root.join("tmp/shop-desktop-scene.png"))
    page.execute_script("document.querySelector('.nl-shop-frame').scrollIntoView({block: 'start'})")
    page.save_screenshot(Rails.root.join("tmp/shop-desktop-catalog.png"))

    set_viewport(390, 844)
    expect_entrance_geometry
    metrics = page.evaluate_script(<<~JS)
      (() => {
        const shell = document.querySelector(".nl-game-layout")
        const main = document.querySelector(".nl-main-area")
        const shop = document.querySelector(".nl-shop-page")
        const frame = document.querySelector(".nl-shop-frame")
        const categories = document.querySelector(".nl-shop-filter-viewport")
        const rows = document.querySelector(".nl-shop-table-viewport")
        const scene = document.querySelector(".nl-building-entrance__image")
        return {
          shellFits: shell.scrollWidth <= window.innerWidth + 1,
          shopFits: shop.scrollWidth <= main.clientWidth + 1,
          frameFits: frame.clientWidth <= main.clientWidth,
          categoriesScroll: categories.scrollWidth > categories.clientWidth,
          rowsScroll: rows.scrollWidth > rows.clientWidth,
          imageLoaded: scene.complete && scene.naturalWidth > 0
        }
      })()
    JS
    expect(metrics).to eq("shellFits" => true, "shopFits" => true, "frameFits" => true,
      "categoriesScroll" => true, "rowsScroll" => true, "imageLoaded" => true)
    page.execute_script("document.querySelector('.nl-shop-frame').scrollIntoView({block: 'start'})")
    page.save_screenshot(Rails.root.join("tmp/shop-mobile-catalog.png"))
    expect(page).to have_css(".nl-shop-category[aria-label='Other']", visible: :all)
  end
end
