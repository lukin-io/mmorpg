# frozen_string_literal: true

# Auto-populate outdoor world with Ashen Veil catalog NPCs by tier bands.
return unless defined?(TileNpc) && defined?(NpcTemplate)

result = Game::World::AshenPopulation.new.call
puts "Ashen world population: placed=#{result.placed} updated=#{result.updated} skipped=#{result.skipped}"
