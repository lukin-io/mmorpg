# frozen_string_literal: true

module Game
  module Equipment
    # Ashen Veil thematic set ladder bonuses (2 / 4 / 6 pieces of the same set).
    # Source: packages/game-data/src/thematic-sets.ts thematicSetLadderBonus.
    class SetBonuses
      SET_META = {
        "blood" => {focus: "attack", name_ru: "Кровь Завесы", name_en: "Veil Blood"},
        "demiurge" => {focus: "magic_power", name_ru: "Демиург", name_en: "Demiurge"},
        "distortion" => {focus: "speed", name_ru: "Искажение", name_en: "Distortion"},
        "judge" => {focus: "armor", name_ru: "Судия", name_en: "Judge"},
        "swamp" => {focus: "hp", name_ru: "Топь", name_en: "Swamp"}
      }.freeze

      # Maps ladder bonus keys → Character equipment / combat keys.
      BONUS_ALIASES = {
        "attack" => "attack",
        "magic_power" => "magic_power",
        "magicpower" => "magic_power",
        "speed" => "speed",
        "armor" => "armor_class",
        "hp" => "hp",
        "maxhp" => "hp",
        "max_hp" => "hp",
        "luck" => "luck",
        "resist" => "resist",
        "strength" => "strength",
        "dexterity" => "dexterity",
        "vitality" => "vitality",
        "intelligence" => "intelligence"
      }.freeze

      Result = Struct.new(:modifiers, :active, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def call
        counts = equipped_set_counts
        modifiers = Hash.new(0)
        active = []

        SET_META.each_key do |set_id|
          n = counts.fetch(set_id, 0)
          next if n < 1

          row = n >= 2 ? ladder_bonus(set_id, n) : {bonus: {}, labels: incomplete_label(set_id, n)}
          active << {set_id:, pieces: n, labels: row[:labels]} if n >= 1
          next if n < 2

          row[:bonus].each do |key, value|
            mapped = BONUS_ALIASES[key.to_s]
            modifiers[mapped] += value.to_i if mapped
          end
        end

        Result.new(modifiers:, active:)
      end

      def self.set_id_for_template(template)
        rules = template.enhancement_rules.to_h
        explicit = rules["set_key"].to_s
        if explicit.start_with?("set-")
          return explicit.delete_prefix("set-")
        end

        key = template.key.to_s
        match = key.match(/\Aset-(blood|demiurge|distortion|judge|swamp)-/)
        match && match[1]
      end

      private

      attr_reader :character

      def equipped_set_counts
        return {} unless character.inventory

        counts = Hash.new(0)
        character.inventory.inventory_items.equipped.includes(:item_template).each do |item|
          next if item.broken?

          set_id = self.class.set_id_for_template(item.item_template)
          counts[set_id] += 1 if set_id
        end
        counts
      end

      def ladder_bonus(set_id, equipped_count)
        meta = SET_META.fetch(set_id)
        focus = meta.fetch(:focus)
        name_ru = meta.fetch(:name_ru)
        name_en = meta.fetch(:name_en)
        bonus = Hash.new(0)
        labels = []
        n = equipped_count.to_i

        if n >= 2
          bonus[focus] += 2
          bonus["luck"] += 1
          labels << {"ru-RU" => "#{name_ru} (2): лёгкий резонанс", "en-US" => "#{name_en} (2): light resonance"}
        end
        if n >= 4
          bonus["armor"] += 3
          bonus["hp"] += 18
          if %w[attack magic_power].include?(focus)
            bonus[focus] += 3
          else
            bonus["attack"] += 2
          end
          labels << {"ru-RU" => "#{name_ru} (4): согласованный контур", "en-US" => "#{name_en} (4): aligned circuit"}
        end
        if n >= 6
          bonus["hp"] += 36
          bonus["resist"] += 4
          bonus[focus] += 5
          labels << {"ru-RU" => "#{name_ru} (6): полный комплект", "en-US" => "#{name_en} (6): full set"}
        end

        {bonus:, labels:}
      end

      def incomplete_label(set_id, n)
        meta = SET_META.fetch(set_id)
        [{
          "ru-RU" => "#{meta.fetch(:name_ru)}: #{n}/6 (бонус с 2)",
          "en-US" => "#{meta.fetch(:name_en)}: #{n}/6 (bonus from 2)"
        }]
      end
    end
  end
end
