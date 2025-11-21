if defined?(User)
  admin = User.find_or_create_by!(email: "admin@neverlands.test") do |user|
    user.password = "ChangeMe123!"
    user.confirmed_at = Time.current
  end
  admin.add_role(:admin)
end

if defined?(Role)
  %i[player moderator gm admin].each do |role_name|
    Role.find_or_create_by!(name: role_name)
  end
end

if defined?(Flipper)
  %i[combat_system guilds housing].each do |feature|
    Flipper.add(feature)
  end
end

if defined?(ChatChannel)
  ChatChannel.find_or_create_by!(slug: "global") do |channel|
    channel.name = "Global"
    channel.channel_type = :global
    channel.system_owned = true
  end
end

if defined?(Profession)
  [
    {name: "Blacksmithing", category: "production"},
    {name: "Alchemy", category: "production"},
    {name: "Herbalism", category: "gathering", gathering: true},
    {name: "Fishing", category: "gathering", gathering: true}
  ].each do |attrs|
    Profession.find_or_create_by!(name: attrs[:name]) do |profession|
      profession.category = attrs[:category]
      profession.gathering = attrs.fetch(:gathering, false)
    end
  end
end

if defined?(PetSpecies)
  PetSpecies.find_or_create_by!(name: "Silver Fox") do |species|
    species.ability_type = "gathering_bonus"
    species.rarity = "rare"
    species.ability_payload = {"gather_bonus" => 0.05}
  end
end

if defined?(GameEvent)
  GameEvent.find_or_create_by!(slug: "winter_festival") do |event|
    event.name = "Winter Festival"
    event.description = "Seasonal quests and cosmetics."
    event.status = :upcoming
    event.starts_at = 1.month.from_now
    event.ends_at = 1.month.from_now + 2.weeks
  end
end
