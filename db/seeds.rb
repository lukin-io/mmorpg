Region.create!(name: "Starter Village", description: "The starting point for adventurers", x_coord: 0, y_coord: 0)
Region.create!(name: "Dark Forest", description: "Dangerous, mysterious woodland", x_coord: 10, y_coord: 5)
Region.create!(name: "Silver City", description: "Central hub for trade and crafting", x_coord: -5, y_coord: 8)

Item.create!(name: "Iron Sword", item_type: "Weapon", rarity: "Common", attrs: {attack: 5})
Item.create!(name: "Leather Armor", item_type: "Armor", rarity: "Common", attrs: {defense: 3})
Item.create!(name: "Healing Potion", item_type: "Consumable", rarity: "Uncommon", attrs: {heal: 20})

leader_character = Character.first
Guild.create!(name: "Warriors of Light", description: "Guild for brave warriors", leader: leader_character)
