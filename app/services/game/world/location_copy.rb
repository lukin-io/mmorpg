# frozen_string_literal: true

module Game
  module World
    # RU/EN presentation for seeded location lobbies. Known English seed strings
    # are mapped through I18n so the active locale wins without requiring a DB rewrite.
    class LocationCopy
      BUILDING_NAME_KEYS = {
        "podgorny_mine" => "game.locations.buildings.podgorny_mine",
        "forpost_resource_exchange" => "game.locations.buildings.resource_exchange",
        "frontier_village_entrance" => "game.locations.buildings.frontier_village"
      }.freeze

      PRESENCE_KEYS = {
        "Dragon Fang, Mine" => "game.locations.presence.dragon_fang_mine",
        "Outpost, Exchange" => "game.locations.presence.outpost_exchange",
        "Podgorny Mine" => "game.locations.buildings.podgorny_mine",
        "Resource Exchange" => "game.locations.buildings.resource_exchange",
        "Village Square" => "game.locations.presence.village_square",
        "Shop" => "game.locations.sections.shop",
        "Frontier Village" => "game.locations.buildings.frontier_village",
        "Клык Дракона, Шахта" => "game.locations.presence.dragon_fang_mine",
        "Форпост, Обмен" => "game.locations.presence.outpost_exchange",
        "Подножная шахта" => "game.locations.buildings.podgorny_mine",
        "Обмен ресурсов" => "game.locations.buildings.resource_exchange",
        "Площадь деревни" => "game.locations.presence.village_square",
        "Пограничная деревня" => "game.locations.buildings.frontier_village",
        "Лавка" => "game.locations.sections.shop"
      }.freeze

      SECTION_BY_KEY = {
        "entrance" => "game.locations.sections.entrance",
        "gallery" => "game.locations.gallery_tab",
        "shop" => "game.locations.sections.shop",
        "sell" => "game.locations.sections.sell",
        "buy" => "game.locations.sections.buy",
        "storage" => "game.locations.sections.storage"
      }.freeze

      FEATURE_BY_KEY = {
        "exit" => "game.locations.features.nature",
        "trading_post" => "game.locations.features.trading_post"
      }.freeze

      FEATURE_BY_LABEL = {
        "Nature" => "game.locations.features.nature",
        "Leave the village" => "game.locations.features.leave_village",
        "Trading Post" => "game.locations.features.trading_post",
        "Природа" => "game.locations.features.nature",
        "Выйти из деревни" => "game.locations.features.leave_village",
        "Торговая лавка" => "game.locations.features.trading_post"
      }.freeze

      SUMMARY_KEYS = {
        "Mine in Podgornaya Village" => "game.locations.summaries.podgorny_entrance",
        "Ashen coal gallery" => "game.locations.gallery_summary",
        "Podgorny Mine" => "game.locations.summaries.podgorny_mine",
        "Шахта в Подгорной деревне" => "game.locations.summaries.podgorny_entrance",
        "Пепельная угольная галерея" => "game.locations.gallery_summary",
        "Подножная шахта" => "game.locations.summaries.podgorny_mine"
      }.freeze

      UNAVAILABLE_KEYS = {
        "Descend" => "game.locations.descend",
        "Processing Point" => "game.locations.processing_point",
        "Спуститься в шахту" => "game.locations.descend",
        "Пункт переработки" => "game.locations.processing_point"
      }.freeze

      RESOURCE_CATEGORY_KEYS = {
        "Fish resources" => "game.locations.resource_categories.fish",
        "Fish components" => "game.locations.resource_categories.fish_components",
        "Cooking resources" => "game.locations.resource_categories.cooking",
        "Plant resources" => "game.locations.resource_categories.plant",
        "Alchemy components" => "game.locations.resource_categories.alchemy",
        "Hunting resources" => "game.locations.resource_categories.hunting",
        "Hunting alchemy components" => "game.locations.resource_categories.hunting_alchemy",
        "Mineral resources" => "game.locations.resource_categories.mineral",
        "Wood" => "game.locations.resource_categories.wood",
        "Wooden blanks" => "game.locations.resource_categories.wooden_blanks",
        "Firewood" => "game.locations.resource_categories.firewood",
        "Alloys and metals" => "game.locations.resource_categories.alloys"
      }.freeze

      SHOP_ITEM_KEYS = {
        "Mining license III" => "game.locations.shop_items.license_iii",
        "Mining license II" => "game.locations.shop_items.license_ii",
        "Mining license I" => "game.locations.shop_items.license_i",
        "Sturdy helmet" => "game.locations.shop_items.sturdy_helmet",
        "Simple helmet" => "game.locations.shop_items.simple_helmet",
        "Лицензия шахтёра III" => "game.locations.shop_items.license_iii",
        "Лицензия шахтёра II" => "game.locations.shop_items.license_ii",
        "Лицензия шахтёра I" => "game.locations.shop_items.license_i",
        "Крепкий шлем" => "game.locations.shop_items.sturdy_helmet",
        "Простой шлем" => "game.locations.shop_items.simple_helmet"
      }.freeze

      def self.building_name(building)
        key = BUILDING_NAME_KEYS[building&.location_key.to_s]
        return I18n.t(key) if key

        presence(building&.name)
      end

      def self.presence(text)
        key = PRESENCE_KEYS[text.to_s]
        return I18n.t(key) if key

        text
      end

      def self.section_label(section)
        section = section.to_h
        key = SECTION_BY_KEY[section["key"].to_s]
        return I18n.t(key) if key

        presence(section["label"])
      end

      def self.feature_label(feature)
        feature = feature.to_h
        key = FEATURE_BY_KEY[feature["key"].to_s] || FEATURE_BY_LABEL[feature["label"].to_s]
        return I18n.t(key) if key

        presence(feature["label"])
      end

      def self.summary_label(text)
        key = SUMMARY_KEYS[text.to_s]
        return I18n.t(key) if key

        text
      end

      def self.unavailable_label(text)
        key = UNAVAILABLE_KEYS[text.to_s]
        return I18n.t(key) if key

        text
      end

      def self.resource_category(text)
        key = RESOURCE_CATEGORY_KEYS[text.to_s]
        return I18n.t(key) if key

        text
      end

      def self.shop_item_name(text)
        key = SHOP_ITEM_KEYS[text.to_s]
        return I18n.t("#{key}.name") if key

        text
      end

      def self.shop_item_details(item)
        key = SHOP_ITEM_KEYS[item.to_h["name"].to_s]
        return Array(I18n.t("#{key}.details")) if key

        Array(item.to_h["details"])
      end

      def self.short_label(text)
        return I18n.t("game.locations.short_village") if text.to_s.match?(/\A(Village|Деревня)\z/i)

        presence(text)
      end
    end
  end
end
