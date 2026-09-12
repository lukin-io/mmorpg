# frozen_string_literal: true

# ==============================================================================
# Arena Rooms
# ==============================================================================
puts "Seeding Arena Rooms..."

if defined?(ArenaRoom)
  arena_rooms = [
    {
      name: "Help Hall", slug: "help", room_type: :help,
      level_min: 0, level_max: 5, alignment_restriction: nil,
      description: "Source-backed first Arena hall for levels 0-5."
    },
    {
      name: "Training Hall",
      slug: "training",
      room_type: :training,
      level_min: 5,
      level_max: 10,
      alignment_restriction: nil,
      description: "Source-backed starter arena room for training fights."
    },
    {
      name: "Trial Hall",
      slug: "trial",
      room_type: :trial,
      level_min: 5,
      level_max: 33,
      alignment_restriction: nil,
      description: "Source-backed unrestricted Arena room for levels 5-33."
    }
  ]
  arena_rooms.concat([
    {name: "Initiation Hall", slug: "initiation", room_type: :initiation, level_min: 9, level_max: 33},
    {name: "Patrons Hall", slug: "patron", room_type: :patron, level_min: 16, level_max: 33}
  ])
  %w[law light balance chaos dark].each do |alignment|
    arena_rooms << {name: "#{alignment.titleize} Hall", slug: alignment, room_type: alignment.to_sym,
                   level_min: 0, level_max: 33, alignment_restriction: alignment}
  end

  arena_rooms.each do |room_data|
    room = ArenaRoom.find_or_initialize_by(slug: room_data[:slug])
    room.assign_attributes(
      name: room_data[:name],
      room_type: room_data[:room_type],
      level_min: room_data[:level_min],
      level_max: room_data[:level_max],
      alignment_restriction: room_data[:alignment_restriction],
      active: true,
      metadata: {description: room_data[:description]}
    )
    room.save!
    puts "  Created/Found ArenaRoom: #{room_data[:name]}"
  end
end

puts "Arena rooms seeding complete!"
