# frozen_string_literal: true

# ------------------------------------------------------------------
# Gameplay feature sandboxes used by flow + feature documentation
# ------------------------------------------------------------------
# Use the users created at the top of the file (first@lukin.io, second@lukin.io)
# Fall back to alternative emails if those don't exist
admin ||= User.find_by(email: "first@lukin.io") || User.find_by(email: "admin@browser-rpg.test")
lukin_user ||= User.find_by(email: "second@lukin.io") || User.find_by(email: "lukin.maksim@gmail.com")

main_character = nil
secondary_character = nil
lukin_character = nil

if defined?(Character) && admin
  main_character = Character.find_or_create_by!(user: admin, name: "max_kerby") do |char|
    char.level = 22
    char.experience = 125_000
    char.alignment = "light"
    char.allocated_stats = {"strength" => 16, "vitality" => 12, "dexterity" => 5}
    char.fatigue_percent = 0
    char.metadata = {}
  end
  main_character.reload
  unless main_character.in_combat?
    main_character.update!(current_hp: main_character.max_hp, current_mp: main_character.max_mp)
  end
  main_character.inventory || main_character.create_inventory!(slot_capacity: 48, weight_capacity: 160)

  secondary_character = Character.find_or_create_by!(user: admin, name: "max_kerby_balance") do |char|
    char.level = 18
    char.experience = 82_000
    char.alignment = "balance"
    char.allocated_stats = {"intelligence" => 18, "vitality" => 6, "dexterity" => 4}
    char.fatigue_percent = 0
    char.metadata = {}
  end
  secondary_character.reload
  unless secondary_character.in_combat?
    secondary_character.update!(current_hp: secondary_character.max_hp, current_mp: secondary_character.max_mp)
  end
  secondary_character.inventory || secondary_character.create_inventory!(slot_capacity: 42, weight_capacity: 130)

  if lukin_user
    lukin_character = Character.find_or_create_by!(user: lukin_user, name: "max_kerby_dark") do |char|
      char.level = 16
      char.experience = 61_000
      char.alignment = "dark"
      char.allocated_stats = {"dexterity" => 14, "strength" => 7, "vitality" => 5}
      char.fatigue_percent = 0
      char.metadata = {}
    end
    lukin_character.reload
    unless lukin_character.in_combat?
      lukin_character.update!(current_hp: lukin_character.max_hp, current_mp: lukin_character.max_mp)
    end
    lukin_character.inventory || lukin_character.create_inventory!(slot_capacity: 36, weight_capacity: 140)
  end
end
