# frozen_string_literal: true

# Equipment slot catalog for the character paper doll.
#
# Order and pixel size mirror the live Neverlands `slots_pla` / `slots_inv` /
# `slots_fight` renderers recorded in
# `doc/design/reference/neverlands_live_style_system.md`. The doll is three
# columns: a 62px left rail, a center portrait with a ring row and a belt-content
# row, and a 62px right rail. Widths and heights are presentation metadata only;
# persisted equipment is keyed by `key`.
module EquipmentSlots
  Slot = Data.define(:key, :label, :width, :height)

  # Left rail, top to bottom. Heights total 335px.
  LEFT = [
    Slot.new(key: "head", label: "Helmet", width: 62, height: 65),
    Slot.new(key: "amulet", label: "Necklace", width: 62, height: 35),
    Slot.new(key: "main_hand", label: "Weapon", width: 62, height: 91),
    Slot.new(key: "legs", label: "Leg Armor", width: 62, height: 81),
    Slot.new(key: "feet", label: "Boots", width: 62, height: 63)
  ].freeze

  # First right-rail row: the pocket and its content share one 62px line.
  POCKET_ROW = [
    Slot.new(key: "pocket", label: "Pocket", width: 20, height: 20),
    Slot.new(key: "pocket_1", label: "Pocket Content", width: 42, height: 20)
  ].freeze

  # Remaining right-rail rows. With the pocket row the heights total 335px.
  RIGHT = [
    Slot.new(key: "bracers", label: "Bracers", width: 62, height: 40),
    Slot.new(key: "hands", label: "Gloves", width: 62, height: 40),
    Slot.new(key: "off_hand", label: "Off-hand", width: 62, height: 91),
    Slot.new(key: "chest", label: "Body Armor", width: 62, height: 83),
    Slot.new(key: "belt", label: "Belt", width: 62, height: 30),
    Slot.new(key: "relic", label: "Relic", width: 62, height: 31)
  ].freeze

  # Center column rows below the portrait.
  RINGS = [
    Slot.new(key: "ring_1", label: "Ring", width: 31, height: 31),
    Slot.new(key: "ring_2", label: "Ring", width: 31, height: 31),
    Slot.new(key: "ring_3", label: "Ring", width: 31, height: 31),
    Slot.new(key: "ring_4", label: "Ring", width: 31, height: 31)
  ].freeze

  BELT_CONTENT = [
    Slot.new(key: "belt_1", label: "Belt Item", width: 20, height: 20),
    Slot.new(key: "belt_2", label: "Belt Item", width: 20, height: 20),
    Slot.new(key: "belt_3", label: "Belt Item", width: 20, height: 20)
  ].freeze

  ORDERED = (LEFT + POCKET_ROW + RIGHT + RINGS + BELT_CONTENT).freeze
  KEYS = ORDERED.map(&:key).freeze
  LABELS = ORDERED.to_h { |slot| [slot.key, slot.label] }.freeze
end
