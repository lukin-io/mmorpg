# frozen_string_literal: true

module EquipmentSlots
  LEFT = [
    ["head", "Helmet"],
    ["amulet", "Necklace"],
    ["main_hand", "Weapon"],
    ["belt", "Belt"],
    ["legs", "Pants"],
    ["feet", "Boots"]
  ].freeze

  RIGHT = [
    ["off_hand", "Weapon/Shield"],
    ["chest", "Armor"],
    ["hands", "Gloves"],
    ["bracers", "Bracers"],
    ["pocket", "Pocket"],
    ["relic", "Relic"]
  ].freeze

  LOWER = [
    ["ring_1", "Ring"],
    ["ring_2", "Ring"],
    ["ring_3", "Ring"],
    ["ring_4", "Ring"],
    ["belt_1", "Belt Item"],
    ["belt_2", "Belt Item"],
    ["belt_3", "Belt Item"],
    ["pocket_1", "Pocket Item"]
  ].freeze

  ORDERED = (LEFT + RIGHT + LOWER).freeze
  KEYS = ORDERED.map(&:first).freeze
  LABELS = ORDERED.to_h.freeze
end
