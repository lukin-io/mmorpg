# frozen_string_literal: true

module Game
  module World
    # Seeds soft-release tree/herb/fish resource groups across Ashen Shore cells.
    class AshenGatherNodes
      NODES = [
        # —— Trees (dig) ——
        {x: 8, y: 8, groups: [
          {"key" => "pine", "kind" => "tree", "label" => "Пепельная сосна", "active" => true},
          {"key" => "ash_herb", "kind" => "herb", "label" => "Пепельная трава", "active" => true}
        ]},
        {x: 9, y: 7, groups: [
          {"key" => "pine", "kind" => "tree", "label" => "Пепельная сосна", "active" => true},
          {"key" => "pine", "kind" => "tree", "label" => "Молодая сосна", "active" => true}
        ]},
        {x: 10, y: 12, groups: [
          {"key" => "ash_oak", "kind" => "tree", "label" => "Дуб Угля", "active" => true},
          {"key" => "ember_fern", "kind" => "herb", "label" => "Угольный папоротник", "active" => true}
        ]},
        {x: 11, y: 11, groups: [
          {"key" => "ash_oak", "kind" => "tree", "label" => "Дуб Угля", "active" => true}
        ]},
        {x: 12, y: 13, groups: [
          {"key" => "ash_oak", "kind" => "tree", "label" => "Дуб Угля", "active" => true},
          {"key" => "salt_sage", "kind" => "herb", "label" => "Соляной шалфей", "active" => true}
        ]},
        {x: 14, y: 9, groups: [
          {"key" => "veil_willow", "kind" => "tree", "label" => "Ива Завесы", "active" => true},
          {"key" => "dust_moss", "kind" => "moss", "label" => "Пыльный мох", "active" => true}
        ]},
        {x: 15, y: 10, groups: [
          {"key" => "veil_willow", "kind" => "tree", "label" => "Ива Завесы", "active" => true},
          {"key" => "veil_bloom", "kind" => "herb", "label" => "Цветок Завесы", "active" => true}
        ]},
        {x: 16, y: 16, groups: [
          {"key" => "soot_birch", "kind" => "tree", "label" => "Берёза сажи", "active" => true}
        ]},
        {x: 17, y: 15, groups: [
          {"key" => "soot_birch", "kind" => "tree", "label" => "Берёза сажи", "active" => true},
          {"key" => "cinder_root", "kind" => "herb", "label" => "Угольный корень", "active" => true}
        ]},
        {x: 18, y: 8, groups: [
          {"key" => "tar_pine", "kind" => "tree", "label" => "Смоляная сосна", "active" => true},
          {"key" => "tar_needle", "kind" => "herb", "label" => "Смоляная хвоя", "active" => true}
        ]},
        {x: 19, y: 14, groups: [
          {"key" => "ember_cedar", "kind" => "tree", "label" => "Кедр углей", "active" => true}
        ]},
        {x: 20, y: 11, groups: [
          {"key" => "resin", "kind" => "resin", "label" => "Смоляной ствол", "active" => true}
        ]},
        {x: 21, y: 9, groups: [
          {"key" => "drift_alder", "kind" => "tree", "label" => "Ольха дрейфа", "active" => true},
          {"key" => "mist_leaf", "kind" => "herb", "label" => "Туманный лист", "active" => true}
        ]},
        {x: 22, y: 17, groups: [
          {"key" => "ash_oak", "kind" => "tree", "label" => "Дуб Угля", "active" => true},
          {"key" => "pine", "kind" => "tree", "label" => "Пепельная сосна", "active" => true}
        ]},
        {x: 7, y: 14, groups: [
          {"key" => "soot_birch", "kind" => "tree", "label" => "Берёза сажи", "active" => true},
          {"key" => "nightshade_ash", "kind" => "herb", "label" => "Пепельный паслён", "active" => true}
        ]},
        {x: 6, y: 10, groups: [
          {"key" => "veil_willow", "kind" => "tree", "label" => "Ива Завесы", "active" => true},
          {"key" => "glow_lichen", "kind" => "moss", "label" => "Светящийся лишайник", "active" => true}
        ]},
        # —— Herb-dense patches (look) ——
        {x: 13, y: 6, groups: [
          {"key" => "ash_herb", "kind" => "herb", "label" => "Пепельная трава", "active" => true},
          {"key" => "ember_fern", "kind" => "herb", "label" => "Угольный папоротник", "active" => true},
          {"key" => "salt_sage", "kind" => "herb", "label" => "Соляной шалфей", "active" => true}
        ]},
        {x: 25, y: 12, groups: [
          {"key" => "veil_bloom", "kind" => "herb", "label" => "Цветок Завесы", "active" => true},
          {"key" => "mist_leaf", "kind" => "herb", "label" => "Туманный лист", "active" => true},
          {"key" => "cinder_root", "kind" => "herb", "label" => "Угольный корень", "active" => true}
        ]},
        {x: 28, y: 20, groups: [
          {"key" => "dust_moss", "kind" => "moss", "label" => "Пыльный мох", "active" => true},
          {"key" => "glow_lichen", "kind" => "moss", "label" => "Светящийся лишайник", "active" => true},
          {"key" => "tar_needle", "kind" => "herb", "label" => "Смоляная хвоя", "active" => true}
        ]},
        {x: 32, y: 15, groups: [
          {"key" => "nightshade_ash", "kind" => "herb", "label" => "Пепельный паслён", "active" => true},
          {"key" => "ash_herb", "kind" => "herb", "label" => "Пепельная трава", "active" => true}
        ]},
        {x: 35, y: 18, groups: [
          {"key" => "ember_cap", "kind" => "plant", "label" => "Угольный гриб", "active" => true},
          {"key" => "silver_thistle", "kind" => "plant", "label" => "Серебряный чертополох", "active" => true}
        ]},
        {x: 42, y: 27, groups: [
          {"key" => "moon_orchid", "kind" => "herb", "label" => "Лунная орхидея", "active" => true}
        ]},
        # —— Fishing shores (fish + bait required) ——
        {x: 30, y: 10, groups: [
          {"key" => "shore_fish", "kind" => "fish", "label" => "Прибрежная рыбалка", "active" => true}
        ], actions: %w[fishing]},
        {x: 31, y: 10, groups: [
          {"key" => "ash_perch", "kind" => "fish", "label" => "Пепельный окунь", "active" => true}
        ], actions: %w[fishing]},
        {x: 70, y: 10, groups: [
          {"key" => "reef_fish", "kind" => "fish", "label" => "Рифовая рыбалка", "active" => true}
        ], actions: %w[fishing]},
        {x: 71, y: 11, groups: [
          {"key" => "veil_eel", "kind" => "fish", "label" => "Угорь Завесы", "active" => true}
        ], actions: %w[fishing]},
        {x: 4, y: 20, groups: [
          {"key" => "salt_carp", "kind" => "fish", "label" => "Соляной карп", "active" => true}
        ], actions: %w[fishing]},
        {x: 5, y: 22, groups: [
          {"key" => "ember_trout", "kind" => "fish", "label" => "Угольная форель", "active" => true},
          {"key" => "ash_perch", "kind" => "fish", "label" => "Пепельный окунь", "active" => true}
        ], actions: %w[fishing]},
        {x: 24, y: 4, groups: [
          {"key" => "drift_smelt", "kind" => "fish", "label" => "Дрейфующая корюшка", "active" => true},
          {"key" => "mist_roach", "kind" => "fish", "label" => "Туманный пескарь", "active" => true}
        ], actions: %w[fishing]},
        {x: 6, y: 23, groups: [
          {"key" => "cinder_pike", "kind" => "fish", "label" => "Угольная щука", "active" => true}
        ], actions: %w[fishing]},
        {x: 38, y: 8, groups: [
          {"key" => "glass_minnow", "kind" => "fish", "label" => "Стеклянный гольян", "active" => true}
        ], actions: %w[fishing]},
        {x: 66, y: 18, groups: [
          {"key" => "veil_blackfin", "kind" => "fish", "label" => "Чернопёрка Завесы", "active" => true}
        ], actions: %w[fishing]}
      ].freeze

      def self.ensure!
        new.call
      end

      def call
        zone = Zone.find_by(name: "Пепельный Берег")
        return unless zone

        NODES.each do |node|
          next unless in_zone_bounds?(zone, node[:x], node[:y])

          cell = MapTileTemplate.find_or_initialize_by(zone: zone.name, x: node[:x], y: node[:y])
          cell.terrain_type = "outdoor" if cell.terrain_type.blank?
          cell.passable = true if cell.new_record? || cell.passable.nil?
          meta = cell.metadata.to_h.deep_dup
          action_types = Array(node[:actions]).presence || %w[digging resource_search]
          meta["local_actions"] = merge_actions(Array(meta["local_actions"]), action_types)
          meta["resource_groups"] = merge_groups(Array(meta["resource_groups"]), node[:groups])
          cell.metadata = meta
          cell.save!
        rescue ActiveRecord::RecordInvalid
          next
        end
      end

      private

      def in_zone_bounds?(zone, x, y)
        width = zone.respond_to?(:width) ? zone.width.to_i : 0
        height = zone.respond_to?(:height) ? zone.height.to_i : 0
        return true if width <= 0 || height <= 0

        x >= 0 && y >= 0 && x < width && y < height
      end
      def merge_actions(existing, action_types)
        list = existing.map { |row| row.is_a?(Hash) ? row.stringify_keys : {} }
        action_types.each do |type|
          next if list.any? { |row| row["type"] == type }

          definition = MapTileTemplate.local_action_definition(type)
          next unless definition

          list << {
            "type" => type,
            "source_id" => definition.fetch("source_id"),
            "active" => true,
            "label" => definition.fetch("default_label")
          }
        end
        list
      end

      def merge_groups(existing, authored)
        by_key = existing.select { |g| g.is_a?(Hash) }.index_by { |g| g["key"].to_s }
        authored.each { |g| by_key[g["key"]] = g.stringify_keys }
        by_key.values
      end
    end
  end
end
