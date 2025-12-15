# frozen_string_literal: true

module Characters
  # Handles server-side vital calculations
  # Manages HP/MP damage, healing, consumption, and regeneration
  #
  # @example Apply damage
  #   service = Characters::VitalsService.new(character)
  #   service.apply_damage(50, source: "Wild Wolf")
  #
  # @example Tick regeneration
  #   service.tick_regeneration
  #
  class VitalsService
    REGEN_TICK_INTERVAL = 1.second
    COMBAT_LOCKOUT = 10.seconds

    attr_reader :character

    def initialize(character)
      @character = character
    end

    # Apply damage to character
    #
    # @param amount [Integer] damage amount
    # @param source [String] damage source (NPC name, player name, etc.)
    # @return [Integer] actual damage dealt
    def apply_damage(amount, source:)
      character.with_lock do
        actual_damage = [amount, character.current_hp].min
        character.current_hp = [0, character.current_hp - amount].max
        character.in_combat = true
        character.last_combat_at = Time.current
        character.save!

        broadcast_vital_update(:damage, actual_damage, source)
        check_death if character.current_hp <= 0

        actual_damage
      end
    end

    # Apply healing to character
    #
    # @param amount [Integer] healing amount
    # @param source [String] healing source (potion, skill, etc.)
    # @return [Integer] actual amount healed
    def apply_healing(amount, source:)
      character.with_lock do
        healed = [amount, character.max_hp - character.current_hp].min
        character.current_hp += healed
        character.save!

        broadcast_vital_update(:heal, healed, source)
        healed
      end
    end

    # Consume mana for skill/spell use
    #
    # @param amount [Integer] mana cost
    # @return [Boolean] true if mana was consumed, false if insufficient
    def consume_mana(amount)
      return false if character.current_mp < amount

      character.with_lock do
        character.current_mp -= amount
        character.save!
        broadcast_vital_update(:mana_use, amount, nil)
      end
      true
    end

    # Restore mana
    #
    # @param amount [Integer] mana amount
    # @param source [String] source (potion, skill, etc.)
    # @return [Integer] actual amount restored
    def restore_mana(amount, source:)
      character.with_lock do
        restored = [amount, character.max_mp - character.current_mp].min
        character.current_mp += restored
        character.save!

        broadcast_vital_update(:mana_restore, restored, source)
        restored
      end
    end

    # Process one regeneration tick
    # Only regenerates when out of combat
    #
    # @return [Boolean] true if regeneration was applied
    def tick_regeneration
      return false unless out_of_combat? && needs_regen?

      character.with_lock do
        hp_gain = hp_per_tick
        mp_gain = mp_per_tick

        character.current_hp = [character.current_hp + hp_gain, character.max_hp].min
        character.current_mp = [character.current_mp + mp_gain, character.max_mp].min
        character.last_regen_tick_at = Time.current
        character.save!

        broadcast_regen_update(hp_gain, mp_gain)
      end

      true
    end

    # Check if character is out of combat
    #
    # @return [Boolean] true if not in combat or combat lockout expired
    def out_of_combat?
      return true unless character.in_combat

      if character.last_combat_at.nil? || character.last_combat_at < COMBAT_LOCKOUT.ago
        character.update!(in_combat: false)
        true
      else
        false
      end
    end

    # Check if character needs regeneration
    #
    # @return [Boolean] true if HP or MP below max
    def needs_regen?
      character.current_hp < character.max_hp || character.current_mp < character.max_mp
    end

    # Calculate HP regen per tick (formula: maxHP / interval)
    #
    # @return [Float] HP to regenerate per tick
    def hp_per_tick
      return 0 if character.hp_regen_interval.nil? || character.hp_regen_interval.zero?
      (character.max_hp.to_f / character.hp_regen_interval).round(2)
    end

    # Calculate MP regen per tick
    #
    # @return [Float] MP to regenerate per tick
    def mp_per_tick
      return 0 if character.mp_regen_interval.nil? || character.mp_regen_interval.zero?
      (character.max_mp.to_f / character.mp_regen_interval).round(2)
    end

    # Calculate HP percentage
    #
    # @return [Float] HP as percentage (0-100)
    def hp_percent
      return 0 if character.max_hp.zero?
      ((character.current_hp.to_f / character.max_hp) * 100).round(1)
    end

    # Calculate MP percentage
    #
    # @return [Float] MP as percentage (0-100)
    def mp_percent
      return 0 if character.max_mp.zero?
      ((character.current_mp.to_f / character.max_mp) * 100).round(1)
    end

    # Returns a summary hash of character stats for display
    #
    # @return [Hash] stats summary with base stats and derived values
    def stats_summary
      stats = character.stats

      {
        current_hp: character.current_hp,
        max_hp: character.max_hp,
        current_mp: character.current_mp,
        max_mp: character.max_mp,
        strength: stats.get(:strength),
        dexterity: stats.get(:dexterity),
        intelligence: stats.get(:intelligence),
        vitality: stats.get(:vitality),
        spirit: stats.get(:spirit),
        attack_power: calculate_attack_power(stats),
        defense: calculate_defense(stats),
        crit_rate: calculate_crit_rate(stats)
      }
    end

    private

    # Calculate attack power from stats
    #
    # @param stats [Game::Systems::StatBlock] character stats
    # @return [Integer] attack power value
    def calculate_attack_power(stats)
      base = stats.get(:strength).to_i * 2
      dex_bonus = stats.get(:dexterity).to_i / 2
      base + dex_bonus + equipment_attack_bonus
    end

    # Calculate defense from stats
    #
    # @param stats [Game::Systems::StatBlock] character stats
    # @return [Integer] defense value
    def calculate_defense(stats)
      base = stats.get(:vitality).to_i
      str_bonus = stats.get(:strength).to_i / 3
      base + str_bonus + equipment_defense_bonus
    end

    # Calculate critical hit rate from stats
    #
    # @param stats [Game::Systems::StatBlock] character stats
    # @return [Integer] crit rate percentage
    def calculate_crit_rate(stats)
      base = 5
      dex_bonus = stats.get(:dexterity).to_i / 5
      luck_bonus = stats.get(:luck).to_i / 10
      [base + dex_bonus + luck_bonus, 100].min
    end

    # Get attack bonus from equipped items
    #
    # @return [Integer] total attack bonus from equipment
    def equipment_attack_bonus
      return 0 unless character.inventory

      character.inventory.inventory_items.equipped.includes(:item_template).sum do |item|
        item.item_template.stat_modifiers&.fetch("attack", 0).to_i
      end
    end

    # Get defense bonus from equipped items
    #
    # @return [Integer] total defense bonus from equipment
    def equipment_defense_bonus
      return 0 unless character.inventory

      character.inventory.inventory_items.equipped.includes(:item_template).sum do |item|
        item.item_template.stat_modifiers&.fetch("defense", 0).to_i
      end
    end

    def broadcast_vital_update(type, amount, source)
      ActionCable.server.broadcast(
        "character:#{character.id}:vitals",
        {
          type: type,
          amount: amount,
          source: source,
          current_hp: character.current_hp,
          max_hp: character.max_hp,
          current_mp: character.current_mp,
          max_mp: character.max_mp,
          hp_percent: hp_percent,
          mp_percent: mp_percent
        }
      )
    end

    def broadcast_regen_update(hp_gain, mp_gain)
      ActionCable.server.broadcast(
        "character:#{character.id}:vitals",
        {
          type: :regen,
          hp_gain: hp_gain.round(1),
          mp_gain: mp_gain.round(1),
          current_hp: character.current_hp,
          current_mp: character.current_mp,
          hp_percent: hp_percent,
          mp_percent: mp_percent
        }
      )
    end

    def check_death
      Characters::DeathHandler.call(character)
    end
  end
end
