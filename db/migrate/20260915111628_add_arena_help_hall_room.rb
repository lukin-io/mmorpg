# frozen_string_literal: true

# Soft-release Help Hall (levels 0-5) so level-zero characters can enter an
# Arena room. Source hall list includes «Зал Помощи» at 0-5.
class AddArenaHelpHallRoom < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:arena_rooms)

    room = ArenaRoom.find_or_initialize_by(slug: "help")
    room.assign_attributes(
      name: "Help Hall",
      room_type: :help,
      level_min: 0,
      level_max: 5,
      alignment_restriction: nil,
      active: true,
      metadata: {description: "Source-backed Help Hall for levels 0-5."}
    )
    room.save!
  end

  def down
    ArenaRoom.find_by(slug: "help")&.destroy!
  end
end
