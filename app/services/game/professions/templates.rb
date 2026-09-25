# frozen_string_literal: true

module Game
  module Professions
    # Ensures craftable Ashen consumable/material templates exist at runtime.
    class Templates
      def self.ensure_craft_items!
        ensure_item!(
          key: "wood_chips",
          name: "Щепа Смолы",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 2,
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "misc",
            "source_name" => "Щепа Смолы",
            "shop" => {"sold" => true, "mode" => "buy", "position" => 80},
            "shop_stock" => {"current" => 500, "max" => 500}
          }
        )
        ensure_item!(
          key: "pine_resin",
          name: "Смола сосны",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 3,
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "misc",
            "source_name" => "Смола сосны",
            "description" => "С живой пепельной сосны — для бинтов и варок."
          }
        )
        ensure_item!(
          key: "ash_oak_plank",
          name: "Доска дуба Угля",
          item_type: "material",
          slot: "material",
          weight: 2,
          stack_limit: 50,
          base_price: 5,
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "misc",
            "source_name" => "Доска дуба Угля",
            "description" => "Плотная доска для полевых наборов."
          }
        )
        ensure_item!(
          key: "veil_willow_bark",
          name: "Кора ивы Завесы",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 4,
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "misc",
            "source_name" => "Кора ивы Завесы",
            "description" => "Горькая кора для сумок лекаря и отваров."
          }
        )
        ensure_item!(
          key: "soot_birch_sap",
          name: "Сок берёзы сажи",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 4,
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "misc",
            "source_name" => "Сок берёзы сажи",
            "description" => "Тёмный сок для приманок и зелий."
          }
        )
        ensure_item!(
          key: "dust_moss",
          name: "Пыльный мох",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 3,
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "misc",
            "source_name" => "Пыльный мох",
            "description" => "Мох берега для лёгких отваров."
          }
        )
        ensure_item!(
          key: "ash_tonic",
          name: "Отвар Пепла",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 18,
          stat_modifiers: {"heal_hp" => 25},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Отвар Пепла",
            "description" => "Простой отвар из мха и коры. +25 HP."
          }
        )
        ensure_item!(
          key: "rat_tail",
          name: "Хвост Крысы Завесы",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 3
        )
        ensure_item!(
          key: "ashen_bait",
          name: "Приманка Завесы",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 5
        )
        ensure_item!(
          key: "ashen_bandage",
          name: "Пепельный бинт",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 12,
          stat_modifiers: {"heal_hp" => 40, "clear_light_injury" => true},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Пепельный бинт",
            "description" => "Полевой бинт Смолокура. +40 HP и снимает лёгкие травмы."
          }
        )
        ensure_item!(
          key: "veil_field_kit",
          name: "Полевой набор Завесы",
          item_type: "consumable",
          slot: "none",
          weight: 2,
          stack_limit: 10,
          base_price: 35,
          stat_modifiers: {"heal_hp" => 80, "clear_light_injury" => true},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Полевой набор Завесы",
            "description" => "Усиленный набор Смолокура. +80 HP и снимает лёгкие травмы."
          }
        )
        ensure_item!(
          key: "ash_herb",
          name: "Пепельная трава",
          item_type: "material",
          slot: "material",
          weight: 1,
          stack_limit: 99,
          base_price: 4,
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "misc",
            "source_name" => "Пепельная трава",
            "description" => "Трава берега для сумок лекаря."
          }
        )
        {
          "ember_fern" => ["Угольный папоротник", "Папоротник для полевых отваров."],
          "salt_sage" => ["Соляной шалфей", "Шалфей соляных отмелей."],
          "veil_bloom" => ["Цветок Завесы", "Редкий цветок для эликсиров."],
          "cinder_root" => ["Угольный корень", "Горький корень для тоников."],
          "tar_needle" => ["Смоляная хвоя", "Хвоя смоляной сосны."],
          "mist_leaf" => ["Туманный лист", "Лист из тумана берега."],
          "nightshade_ash" => ["Пепельный паслён", "Осторожный реагент лекаря."],
          "glow_lichen" => ["Светящийся лишайник", "Лишайник для ночных варок."],
          "ember_cedar_plank" => ["Доска кедра углей", "Кедровая доска для наборов."],
          "drift_alder_wood" => ["Древесина ольхи дрейфа", "Лёгкая ольха для приманок."],
          "ash_perch" => ["Пепельный окунь", "Рыба прибрежных клеток."],
          "mist_roach" => ["Туманный пескарь", "Мелкая рыба туманных отмелей."],
          "veil_eel" => ["Угорь Завесы", "Угорь рифовых клеток."],
          "salt_carp" => ["Соляной карп", "Карп соляных луж."],
          "ember_trout" => ["Угольная форель", "Форель угольных струй."],
          "cinder_pike" => ["Угольная щука", "Крупная щука угольных струй."],
          "drift_smelt" => ["Дрейфующая корюшка", "Мелкая рыба дрейфа."],
          "iron_ore" => ["Железная руда", "Руда железной жилы."],
          "silver_ore" => ["Серебряная руда", "Руда серебряной жилы."],
          "coal_chunk" => ["Кусок угля", "Уголь разреза."],
          "ash_crystal" => ["Кристалл Пепла", "Кристалл грота."],
          "ember_cap" => ["Угольный гриб", "Тёплый гриб для укрепляющих зелий."],
          "silver_thistle" => ["Серебряный чертополох", "Редкое растение солончаков."],
          "moon_orchid" => ["Лунная орхидея", "Редкий цветок туманных низин."],
          "ash_wolf_pelt" => ["Шкура пепельного волка", "Редкая шкура хищника."],
          "veil_boar_hide" => ["Кожа вепря Завесы", "Редкая прочная кожа."],
          "cinder_drake_scale" => ["Чешуя угольного дракона", "Редкая жаростойкая чешуя."],
          "mist_spider_silk" => ["Шёлк туманного паука", "Редкое лёгкое волокно."],
          "veil_blackfin" => ["Чернопёрка Завесы", "Редкая рыба глубоких заводей."],
          "glass_minnow" => ["Стеклянный гольян", "Мелкая прозрачная рыба."]
        }.each do |key, (name, description)|
          ensure_item!(
            key:,
            name:,
            item_type: "material",
            slot: "material",
            weight: 1,
            stack_limit: 99,
            base_price: 4,
            enhancement_rules: {
              "inventory_family" => key.end_with?("_ore", "_chunk", "crystal") || key.start_with?("ash_crystal") ? "resources" : (key.match?(/perch|eel|carp|trout|smelt|roach|pike|blackfin|minnow/) ? "fishing" : "things"),
              "subcategory" => "misc",
              "source_name" => name,
              "description" => description
            }
          )
        end
        PotionCatalog.ensure_templates!
        {
          "ash_ranger_jacket" => ["Куртка пепельного следопыта", "chest", 12, {"defense" => 14, "dodge" => 5}],
          "ash_ranger_boots" => ["Сапоги пепельного следопыта", "feet", 10, {"defense" => 7, "dodge" => 7}],
          "ash_warden_blade" => ["Клинок хранителя Пепла", "main_hand", 20, {"attack" => 22, "accuracy" => 6, "weapon_family" => "sword"}],
          "ash_forager_gloves" => ["Перчатки собирателя Пепла", "hands", 10, {"defense" => 6, "gather_speed" => 8}],
          "ash_battle_helm" => ["Боевой шлем Пепла", "head", 18, {"defense" => 18, "accuracy" => 5}],
          "ash_battle_mail" => ["Боевая кольчуга Пепла", "chest", 25, {"defense" => 28, "max_hp" => 45}]
        }.each do |key, (name, slot, level, mods)|
          ensure_item!(
            key:,
            name:,
            item_type: "equipment",
            slot:,
            weight: slot == "chest" ? 8 : 4,
            stack_limit: 1,
            base_price: 180 + (level * 8),
            durability_max: 100,
            requirements: {"level" => level},
            stat_modifiers: mods,
            enhancement_rules: {
              "inventory_family" => "things",
              "subcategory" => slot == "main_hand" ? "weapons" : "armor",
              "source_name" => name,
              "description" => "Редкое ремесленное снаряжение. Требуется уровень #{level}."
            }
          )
        end
        ensure_item!(
          key: "grilled_ash_perch",
          name: "Жареный окунь Пепла",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 18,
          stat_modifiers: {"heal_hp" => 30},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Жареный окунь Пепла",
            "description" => "Простая еда рыбака. +30 HP.",
            "food" => true
          }
        )
        ensure_item!(
          key: "veil_fish_stew",
          name: "Уха Завесы",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 10,
          base_price: 48,
          stat_modifiers: {"heal_hp" => 70, "clear_light_injury" => true},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Уха Завесы",
            "description" => "Сытная уха. +70 HP, снимает лёгкие травмы.",
            "food" => true
          }
        )
        ensure_item!(
          key: "smoked_cinder_pike",
          name: "Копчёная угольная щука",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 15,
          base_price: 36,
          stat_modifiers: {"heal_hp" => 50},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Копчёная угольная щука",
            "description" => "Копчёная щука. +50 HP.",
            "food" => true
          }
        )
        ensure_item!(
          key: "mist_roach_cakes",
          name: "Лепёшки из пескаря",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 16,
          stat_modifiers: {"heal_hp" => 25},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Лепёшки из пескаря",
            "description" => "Простая еда из туманного пескаря. +25 HP.",
            "food" => true
          }
        )
        ensure_item!(
          key: "pike_broth",
          name: "Уха из щуки",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 12,
          base_price: 28,
          stat_modifiers: {"heal_hp" => 30, "clear_light_injury" => true},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Уха из щуки",
            "description" => "Лечебный бульон. +30 HP, лёгкие травмы."
          }
        )
        ensure_item!(
          key: "salt_elixir",
          name: "Соляной эликсир",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 15,
          base_price: 32,
          stat_modifiers: {"heal_hp" => 40},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Соляной эликсир",
            "description" => "Эликсир из шалфея и карпа. +40 HP."
          }
        )
        ensure_item!(
          key: "ember_salve",
          name: "Угольная мазь",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 15,
          base_price: 32,
          stat_modifiers: {"heal_hp" => 35, "clear_injury_tier" => "light"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "consumables",
            "source_name" => "Угольная мазь",
            "description" => "Мазь из папоротника и корня. +35 HP, лёгкие травмы."
          }
        )
        {
          "ashen_hatchet" => ["Топор Угля", "Для рубки деревьев (Dig). 50 успешных сборов.", 50],
          "ashen_sickle" => ["Серп Пепла", "Для сбора трав (Look). 50 успешных сборов.", 50],
          "ashen_fishing_rod" => ["Удочка Завесы", "Для рыбалки (Fish). 60 успешных уловов.", 60]
        }.each do |key, (name, description, durability)|
          ensure_item!(
            key:,
            name:,
            item_type: "tool",
            slot: "none",
            weight: 2,
            stack_limit: 1,
            base_price: 40,
            durability_max: durability,
            enhancement_rules: {
              "inventory_family" => "things",
              "subcategory" => "tools",
              "source_name" => name,
              "description" => description,
              "gather_tool" => true
            }
          )
        end
        {
          "scroll_veil_ember" => ["Свиток Угольной Искры", "veil_ember", 120],
          "scroll_ash_spark" => ["Свиток Пепельной Вспышки", "ash_spark", 180],
          "scroll_salt_lance" => ["Свиток Соляного Копья", "salt_lance", 250]
        }.each do |key, (name, magic_key, price)|
          ensure_item!(
            key:,
            name:,
            item_type: "consumable",
            slot: "none",
            weight: 1,
            stack_limit: 20,
            base_price: 0,
            stat_modifiers: {"inject_attack_key" => magic_key},
            enhancement_rules: {
              "inventory_family" => "things",
              "subcategory" => "scrolls",
              "source_name" => name,
              "description" => "Боевой свиток мага Завесы. Открывает магическую атаку «#{magic_key}» в бою.",
              "premium_currency" => "nv",
              "premium_price" => price,
              "magic_scroll" => true
            }
          )
        end
        ensure_item!(
          key: "healer_bag_light",
          name: "Сумка новичка-лекаря",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 40,
          stat_modifiers: {"heal_hp" => 30, "clear_injury_tier" => "light"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "aid_kits",
            "source_name" => "Сумка новичка-лекаря",
            "description" => "Снимает лёгкие травмы и лечит 30 HP."
          }
        )
        ensure_item!(
          key: "healer_bag_heavy",
          name: "Сумка опытного лекаря",
          item_type: "consumable",
          slot: "none",
          weight: 2,
          stack_limit: 10,
          base_price: 90,
          stat_modifiers: {"heal_hp" => 60, "clear_injury_tier" => "heavy"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "aid_kits",
            "source_name" => "Сумка опытного лекаря",
            "description" => "Снимает лёгкие и тяжёлые травмы, лечит 60 HP."
          }
        )
        ensure_item!(
          key: "healer_bag_combat",
          name: "Сумка мастера-лекаря",
          item_type: "consumable",
          slot: "none",
          weight: 3,
          stack_limit: 5,
          base_price: 200,
          stat_modifiers: {"heal_hp" => 100, "clear_injury_tier" => "combat"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "aid_kits",
            "source_name" => "Сумка мастера-лекаря",
            "description" => "Снимает любые травмы, включая боевые. Лечит 100 HP."
          }
        )
        ensure_item!(
          key: "assault_scroll_peaceful",
          name: "Свиток нападения (Мирный)",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 0,
          stat_modifiers: {"assault_scroll_kind" => "peaceful"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "scrolls",
            "source_name" => "Свиток нападения (Мирный)",
            "description" => "PvP без гарантированной травмы. Списывается при «Напасть» или заявке арены.",
            "premium_currency" => "nv",
            "premium_price" => 80,
            "assault_scroll" => true
          }
        )
        ensure_item!(
          key: "assault_scroll_normal",
          name: "Свиток нападения (Обычный)",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 0,
          stat_modifiers: {"assault_scroll_kind" => "normal"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "scrolls",
            "source_name" => "Свиток нападения (Обычный)",
            "description" => "Стандартная PvP-травматичность (лёгкая/средняя). Списывается при нападении.",
            "premium_currency" => "nv",
            "premium_price" => 150,
            "assault_scroll" => true
          }
        )
        ensure_item!(
          key: "assault_scroll_bloody",
          name: "Свиток нападения (Кровавый)",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 0,
          stat_modifiers: {"assault_scroll_kind" => "bloody"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "scrolls",
            "source_name" => "Свиток нападения (Кровавый)",
            "description" => "Гарантирует тяжёлую травму проигравшему. Списывается при нападении.",
            "premium_currency" => "nv",
            "premium_price" => 350,
            "assault_scroll" => true
          }
        )
        ensure_item!(
          key: "combat_trauma_scroll",
          name: "Свиток боевой травмы (наследие)",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 0,
          stat_modifiers: {"assault_scroll_kind" => "bloody"},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "scrolls",
            "source_name" => "Свиток боевой травмы",
            "description" => "Устаревший ключ: работает как Кровавый свиток нападения.",
            "premium_currency" => "nv",
            "premium_price" => 350,
            "assault_scroll" => true,
            "legacy_bloody" => true
          }
        )
        ensure_item!(
          key: "protection_scroll",
          name: "Свиток защиты",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 0,
          stat_modifiers: {"join_as_protector" => true},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "scrolls",
            "source_name" => "Свиток защиты",
            "description" => "Позволяет войти в любой идущий бой защитником стороны А или Б. Без требования уровня.",
            "premium_currency" => "nv",
            "premium_price" => 250,
            "protection_scroll" => true
          }
        )
        ensure_item!(
          key: "combat_heal_scroll",
          name: "Свиток снятия боевой травмы",
          item_type: "consumable",
          slot: "none",
          weight: 1,
          stack_limit: 20,
          base_price: 0,
          stat_modifiers: {"clear_injury_tier" => "combat", "heal_hp" => 50},
          enhancement_rules: {
            "inventory_family" => "things",
            "subcategory" => "scrolls",
            "source_name" => "Свиток снятия боевой травмы",
            "description" => "Снимает тяжёлые и боевые травмы. Покупается за серебро (NV).",
            "premium_currency" => "nv",
            "premium_price" => 200
          }
        )
      end

      def self.ensure_item!(attrs)
        item = ItemTemplate.find_or_initialize_by(key: attrs.fetch(:key))
        item.assign_attributes(
          name: attrs.fetch(:name),
          item_type: attrs.fetch(:item_type),
          slot: attrs.fetch(:slot),
          weight: attrs.fetch(:weight),
          stack_limit: attrs.fetch(:stack_limit),
          base_price: attrs[:base_price] || 0,
          durability_max: attrs[:durability_max] || 1,
          requirements: attrs[:requirements] || {},
          stat_modifiers: attrs[:stat_modifiers] || {},
          enhancement_rules: attrs[:enhancement_rules] || item.enhancement_rules.to_h
        )
        item.save!
        item
      end
      private_class_method :ensure_item!
    end
  end
end
