# frozen_string_literal: true

module Game
  module Professions
    # Ashen herbalism potion catalog: blood-tiered timed buffs (1 hour).
    # Stronger blood tier => higher mods, craft skill, shop price.
    class PotionCatalog
      DURATION = 3_600

      # key => {name:, blood:, level:, mods:, price:, craft_price_hint:, inputs:, min_skill:}
      # blood: 1..3 (Кровь I/II/III)
      POTIONS = {
        "strength_brew" => {
          name: "Отвар силы", blood: 1, level: 1,
          mods: {"attack" => 8}, price: 58,
          inputs: {cinder_root: 2, ember_cap: 2, ash_herb: 2}, min_skill: 0
        },
        "ironbark_elixir" => {
          name: "Эликсир железной коры", blood: 1, level: 3,
          mods: {"defense" => 10}, price: 66,
          inputs: {veil_willow_bark: 2, ash_oak_plank: 1, dust_moss: 2}, min_skill: 2
        },
        "hunter_eye_draught" => {
          name: "Настой глаза охотника", blood: 1, level: 5,
          mods: {"accuracy" => 12}, price: 62,
          inputs: {silver_thistle: 2, mist_leaf: 2, ember_trout: 1}, min_skill: 5
        },
        "mist_step_tonic" => {
          name: "Тоник туманного шага", blood: 1, level: 5,
          mods: {"dodge" => 10}, price: 64,
          inputs: {moon_orchid: 1, glow_lichen: 2, mist_roach: 2}, min_skill: 6
        },
        "veil_vigor_elixir" => {
          name: "Эликсир бодрости Завесы", blood: 1, level: 8,
          mods: {"max_hp" => 80}, price: 78,
          inputs: {nightshade_ash: 2, veil_bloom: 2, cinder_pike: 1}, min_skill: 10
        },
        "gather_tonic" => {
          name: "Тоник собирателя", blood: 1, level: 2,
          mods: {"gather_speed" => 15}, price: 60,
          inputs: {tar_needle: 2, salt_sage: 2, ember_cap: 1}, min_skill: 3
        },
        "fisher_oil" => {
          name: "Рыбацкое масло", blood: 1, level: 3,
          mods: {"fishing_skill" => 8}, price: 55,
          inputs: {veil_eel: 1, drift_smelt: 2, salt_sage: 1}, min_skill: 4
        },
        "ashen_luck_sip" => {
          name: "Глоток удачи Пепла", blood: 1, level: 4,
          mods: {"luck" => 6}, price: 70,
          inputs: {veil_bloom: 1, salt_sage: 2, wood_chips: 2}, min_skill: 4
        },
        "mindfire_tea" => {
          name: "Чай огня разума", blood: 1, level: 6,
          mods: {"intelligence" => 5, "accuracy" => 4}, price: 72,
          inputs: {ember_fern: 2, mist_leaf: 2, dust_moss: 1}, min_skill: 7
        },
        "shore_breeze_tonic" => {
          name: "Тоник берегового ветра", blood: 1, level: 4,
          mods: {"dodge" => 6, "gather_speed" => 8}, price: 68,
          inputs: {mist_leaf: 2, drift_smelt: 1, glow_lichen: 1}, min_skill: 5
        },
        # —— Blood II (combined) ——
        "blood2_war_draught" => {
          name: "Боевой настой Крови II", blood: 2, level: 12,
          mods: {"attack" => 14, "defense" => 10}, price: 140,
          inputs: {cinder_root: 3, veil_willow_bark: 2, ember_cap: 3, ash_herb: 3}, min_skill: 14
        },
        "blood2_predator_oil" => {
          name: "Масло хищника Крови II", blood: 2, level: 12,
          mods: {"attack" => 10, "accuracy" => 14, "dodge" => 6}, price: 155,
          inputs: {silver_thistle: 3, moon_orchid: 2, ember_trout: 2, nightshade_ash: 1}, min_skill: 16
        },
        "blood2_oakheart" => {
          name: "Дубовое сердце Крови II", blood: 2, level: 14,
          mods: {"defense" => 16, "max_hp" => 120}, price: 165,
          inputs: {ash_oak_plank: 2, veil_willow_bark: 3, veil_bloom: 2, cinder_pike: 1}, min_skill: 18
        },
        "blood2_field_brew" => {
          name: "Полевой отвар Крови II", blood: 2, level: 10,
          mods: {"gather_speed" => 22, "fishing_skill" => 12, "max_hp" => 40}, price: 130,
          inputs: {tar_needle: 3, salt_sage: 3, veil_eel: 1, ember_cap: 2}, min_skill: 12
        },
        "blood2_shadow_step" => {
          name: "Шаг тени Крови II", blood: 2, level: 13,
          mods: {"dodge" => 16, "accuracy" => 8, "luck" => 4}, price: 150,
          inputs: {moon_orchid: 2, glow_lichen: 3, mist_roach: 3, nightshade_ash: 2}, min_skill: 15
        },
        "blood2_sage_focus" => {
          name: "Фокус мудреца Крови II", blood: 2, level: 14,
          mods: {"intelligence" => 8, "accuracy" => 10, "max_hp" => 50}, price: 148,
          inputs: {ember_fern: 3, mist_leaf: 3, silver_thistle: 2, salt_carp: 1}, min_skill: 17
        },
        # —— Blood III (strong combined) ——
        "blood3_warlord_elixir" => {
          name: "Эликсир полководца Крови III", blood: 3, level: 22,
          mods: {"attack" => 22, "defense" => 18, "accuracy" => 12, "max_hp" => 160}, price: 320,
          inputs: {cinder_root: 5, veil_willow_bark: 4, nightshade_ash: 3, cinder_pike: 2, veil_bloom: 3}, min_skill: 28
        },
        "blood3_phantom_nectar" => {
          name: "Нектар фантома Крови III", blood: 3, level: 20,
          mods: {"dodge" => 22, "accuracy" => 16, "luck" => 8, "attack" => 10}, price: 300,
          inputs: {moon_orchid: 3, glow_lichen: 4, mist_roach: 4, silver_thistle: 3, ember_trout: 2}, min_skill: 26
        },
        "blood3_harvest_crown" => {
          name: "Корона жатвы Крови III", blood: 3, level: 18,
          mods: {"gather_speed" => 35, "fishing_skill" => 20, "max_hp" => 90, "defense" => 8}, price: 280,
          inputs: {tar_needle: 4, salt_sage: 4, veil_eel: 2, ember_cap: 3, ash_oak_plank: 2}, min_skill: 24
        },
        "blood3_veil_ascendant" => {
          name: "Возвышение Завесы Крови III", blood: 3, level: 25,
          mods: {"attack" => 18, "defense" => 18, "dodge" => 12, "accuracy" => 12, "max_hp" => 200, "luck" => 6}, price: 380,
          inputs: {veil_bloom: 4, nightshade_ash: 4, cinder_drake_scale: 1, ash_wolf_pelt: 1, cinder_pike: 2}, min_skill: 32
        },
        "blood3_mind_fortress" => {
          name: "Крепость разума Крови III", blood: 3, level: 21,
          mods: {"intelligence" => 12, "accuracy" => 14, "defense" => 10, "max_hp" => 100}, price: 290,
          inputs: {ember_fern: 4, mist_leaf: 4, silver_thistle: 3, veil_willow_bark: 3, salt_carp: 2}, min_skill: 27
        }
      }.freeze

      MOD_LABELS = {
        "attack" => "Атака",
        "defense" => "Защита",
        "accuracy" => "Точность",
        "dodge" => "Уклон",
        "max_hp" => "Макс. HP",
        "gather_speed" => "Скорость сбора %",
        "fishing_skill" => "Рыбалка",
        "luck" => "Удача",
        "intelligence" => "Знания"
      }.freeze

      def self.each_potion(&)
        POTIONS.each(&)
      end

      def self.fetch(key)
        POTIONS[key.to_s]
      end

      def self.shop_price(key)
        row = fetch(key)
        return nil unless row

        # Buying is intentionally ~2.5–3× craft material value proxy (base_price).
        (row[:price] * 2.7).round
      end

      def self.mods_summary(mods)
        mods.to_h.map do |key, value|
          label = MOD_LABELS[key.to_s] || key.to_s
          signed = value.to_i.positive? ? "+#{value.to_i}" : value.to_i.to_s
          "#{label} #{signed}"
        end.join(", ")
      end

      def self.tooltip_for(buff)
        mods = buff.fetch("mods", {})
        name = buff["label"].presence || buff["key"]
        "#{name}\n#{mods_summary(mods)}\n#{I18n.t("game.sheet.buff_duration_hour", default: "1 час")}"
      end

      def self.ensure_templates!
        POTIONS.each do |key, row|
          blood = row.fetch(:blood)
          Game::Professions::Templates.send(:ensure_item!,
            key:,
            name: row.fetch(:name),
            item_type: "consumable",
            slot: "none",
            weight: 1,
            stack_limit: 15,
            base_price: row.fetch(:price),
            requirements: {"level" => row.fetch(:level)},
            stat_modifiers: {
              "buff" => row.fetch(:mods),
              "buff_duration_seconds" => DURATION,
              "blood_tier" => blood
            },
            enhancement_rules: {
              "inventory_family" => "elixirs",
              "subcategory" => "potions",
              "source_name" => row.fetch(:name),
              "description" => "Кровь #{roman(blood)}. #{mods_summary(row.fetch(:mods))}. Действует 1 час.",
              "blood_tier" => blood,
              "potion_icon" => "blood#{blood}"
            }
          )
        end
      end

      def self.recipe_entries
        POTIONS.each_with_object({}) do |(key, row), acc|
          acc[key] = {
            "profession" => "ash_herbalist",
            "title_ru" => row.fetch(:name),
            "title_en" => key.tr("_", " ").split.map(&:capitalize).join(" "),
            "summary_ru" => "Кровь #{roman(row.fetch(:blood))}: #{mods_summary(row.fetch(:mods))} (1 час).",
            "summary_en" => "Blood #{roman(row.fetch(:blood))}: timed buff 1h.",
            "inputs" => row.fetch(:inputs).transform_keys(&:to_s),
            "output" => {"item_key" => key, "quantity" => 1},
            "skill_gain" => row.fetch(:blood) + 1,
            "min_skill" => row.fetch(:min_skill)
          }
        end
      end

      def self.roman(tier)
        {1 => "I", 2 => "II", 3 => "III"}.fetch(tier.to_i, tier.to_s)
      end
    end
  end
end
