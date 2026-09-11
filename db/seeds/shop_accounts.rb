# frozen_string_literal: true

# Only Forpost has an observed starting economy. A second Shop must be
# authored independently; its balances and assortment are never cloned here.
zone = Zone.find_by(name: Game::World::CityCatalog.node("main").fetch("zone_name"))
shop = CityHotspot.find_by(zone:, key: "shop") if zone
if shop
  ApplicationRecord.transaction do
    shop.lock!
    account = ShopAccount.find_or_create_by!(location: shop) do |record|
      record.nv_balance = BigDecimal("99977307.40")
    end
    account.lock!
    # Historical templates may still be owned, but only these captured stock
    # identities belong to this Shop. Old generic stock JSON is not authority.
    starter_goods = JSON.parse(File.read(Rails.root.join("db/seeds/data/starter_shop.json")))
    stock_keys = starter_goods.map { |item| item.fetch("key") } +
      %w[knowledge_ring dexterity_ring soul_hunter_pendant
        trading_license_i trading_license_ii trading_license_iii doctor_license_i doctor_license_ii doctor_license_iii]
    ItemTemplate.where(key: stock_keys).find_each do |template|
      captured = template.shop_stock
      next unless captured.is_a?(Hash) && captured["current"].is_a?(Integer)

      # Re-running content seeds never resets traded stock or merchant funds.
      account.shop_stocks.find_or_create_by!(item_template: template) do |stock|
        stock.current = captured.fetch("current")
        stock.maximum = captured["max"]
      end
    end
  end
end
