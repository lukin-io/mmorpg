# frozen_string_literal: true

module Game
  module World
    # Maps atlas herb-group ids and legacy English labels onto Ashen plant names
    # for outdoor map chrome (Neverlands-style green resource text).
    class ResourceLabel
      HERB_GROUPS = {
        1 => "Пепельная трава",
        2 => "Луговой клевер",
        3 => "Соляной шалфей",
        4 => "Угольный папоротник",
        5 => "Туманный лист",
        6 => "Лунная орхидея",
        7 => "Угольный корень",
        8 => "Пепельный паслён",
        9 => "Светящийся лишайник",
        10 => "Цветок Завесы"
      }.freeze

      TREE_GROUPS = {
        1 => "Пепельная берёза",
        2 => "Дрейф-ольха",
        3 => "Угольный дуб",
        4 => "Соляная ива",
        5 => "Туманная ель"
      }.freeze

      ENGLISH_ACTION_LABELS = [
        "Look Around", "Drink", "Fish", "Dig", "Mine", "Forage", "Harvest"
      ].freeze

      def self.for_group(group)
        new.for_group(group)
      end

      def for_group(group)
        group = group.to_h
        key = group["key"].to_s
        label = group["label"].to_s.strip
        if (m = key.match(/\Aherbs?[_\s-]*(\d+)\z/i)) || (m = label.match(/\A(?:Herb\s*group|Группа\s*трав)\s*#?\s*(\d+)\z/i))
          return HERB_GROUPS.fetch(m[1].to_i) { "Пепельная трава" }
        end
        if (m = key.match(/\Atrees?[_\s-]*(\d+)\z/i)) || (m = label.match(/\A(?:Tree\s*group|Группа\s*деревьев)\s*#?\s*(\d+)\z/i))
          return TREE_GROUPS.fetch(m[1].to_i) { "Пепельная берёза" }
        end
        return if ENGLISH_ACTION_LABELS.include?(label)
        return if label.match?(/\A(?:look|drink|fish|dig|mine|forage|harvest)\z/i)
        return if label.match?(/\A(?:Herb|Tree)\s*group\b/i)

        label.presence || key.presence
      end
    end
  end
end
