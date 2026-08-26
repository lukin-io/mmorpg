# frozen_string_literal: true

module Arena
  # Applies the source-backed per-fight durability chance to each equipped
  # durable item. A successful roll removes exactly one durability point.
  class EquipmentWearResolver
    ARENA_CHANCES = {"victory" => 0, "draw" => 0, "defeat" => 1}.freeze
    OTHER_FIGHT_CHANCES = {"victory" => 2, "draw" => 30, "defeat" => 50}.freeze
    ROLL_SCALE = 10_000
    BASIS_POINTS_PER_PERCENT = 100

    Result = Data.define(:character_id, :chance_percent, :item_ids)

    def initialize(match:, rng: Random.new)
      @match = match
      @rng = rng
    end

    def call
      match.arena_participations.players.includes(character: {inventory: :inventory_items}).filter_map do |participation|
        character = participation.character
        next unless character&.inventory

        chance = chance_for(character, participation.result)
        changed = character.inventory.inventory_items.equipped.select do |item|
          item.durable? && !item.broken? && durability_loss?(chance)
        end
        changed.each { |item| item.decrement_durability!(1) }

        participation.update!(
          metadata: participation.metadata.to_h.merge(
            "equipment_wear" => {
              "chance_percent" => chance,
              "item_ids" => changed.map(&:id)
            }
          )
        )

        Result.new(character_id: character.id, chance_percent: chance, item_ids: changed.map(&:id))
      end
    end

    private

    attr_reader :match, :rng

    def chance_for(character, result)
      chances = match.metadata.to_h["source"] == "world_npc" ? OTHER_FIGHT_CHANCES : ARENA_CHANCES
      chance = chances.fetch(result.to_s, 0)
      character.owns_perk?(:careful_fighter) ? chance / 2.0 : chance
    end

    def durability_loss?(chance_percent)
      return false unless chance_percent.positive?

      rng.rand(ROLL_SCALE) < (chance_percent * BASIS_POINTS_PER_PERCENT).to_i
    end
  end
end
