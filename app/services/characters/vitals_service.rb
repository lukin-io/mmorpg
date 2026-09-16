# frozen_string_literal: true

module Characters
  # Handles server-side vital calculations
  # Manages HP/MP damage, healing, consumption, and regeneration
  #
  # @example Apply damage
  #   service = Characters::VitalsService.new(character)
  #   service.apply_damage(50, source: "Plague Rat")
  #
  # @example Tick regeneration
  #   service.tick_regeneration
  #
  class VitalsService
    REGEN_TICK_INTERVAL = 1.second
    COMBAT_LOCKOUT = 10.seconds

    attr_reader :character

    def initialize(character, clock: -> { Time.current })
      @character = character
      @clock = clock
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

        actual_damage
      end
    end

    # Apply healing to character
    #
    # @param amount [Integer] healing amount
    # @param source [String] healing source (item name or captured source)
    # @return [Integer] actual amount healed
    def apply_healing(amount, source:)
      character.with_lock do
        healed = [amount, effective_max_hp - character.current_hp].min
        character.current_hp += healed
        character.save!

        healed
      end
    end

    # Consume mana for captured magic/action use
    #
    # @param amount [Integer] mana cost
    # @return [Boolean] true if mana was consumed, false if insufficient
    def consume_mana(amount)
      return false unless amount.is_a?(Numeric) && amount >= 0

      character.with_lock do
        return false if character.current_mp < amount
        character.current_mp -= amount
        character.save!
      end
      true
    end

    # Restore mana
    #
    # @param amount [Integer] mana amount
    # @param source [String] source (item name or captured source)
    # @return [Integer] actual amount restored
    def restore_mana(amount, source:)
      character.with_lock do
        restored = [amount, effective_max_mp - character.current_mp].min
        character.current_mp += restored
        character.save!

        restored
      end
    end

    # Process one regeneration tick
    # Only regenerates when out of combat
    #
    # @return [Boolean] true if regeneration was applied
    def tick_regeneration
      character.with_lock do
        now = @clock.call
        return false unless out_of_combat? && needs_regen?

        anchor = [character.last_regen_tick_at || character.created_at, character.last_combat_at].compact.max || now
        elapsed = [now - anchor, 0].max
        return false if elapsed < 1

        remainder = character.metadata.to_h.fetch("vital_remainders", {})
        hp = hp_per_tick * elapsed + remainder.fetch("hp", 0).to_f
        mp = mp_per_tick * elapsed + remainder.fetch("mp", 0).to_f
        character.update!(
          current_hp: [character.current_hp + hp.floor, effective_max_hp].min,
          current_mp: [character.current_mp + mp.floor, effective_max_mp].min,
          in_combat: false, last_regen_tick_at: now,
          metadata: character.metadata.to_h.merge("vital_remainders" => {"hp" => hp % 1, "mp" => mp % 1})
        )
        true
      end
    end

    def out_of_combat?
      !character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists? &&
        (!character.in_combat || character.last_combat_at.nil? || character.last_combat_at <= @clock.call - COMBAT_LOCKOUT)
    end

    # Check if character needs regeneration
    #
    # @return [Boolean] true if HP or MP below max
    def needs_regen?
      character.current_hp < effective_max_hp || character.current_mp < effective_max_mp
    end

    # Calculate HP regen per tick (formula: maxHP / interval)
    #
    # @return [Float] HP to regenerate per tick
    def hp_per_tick
      recovery_rate(:self_healing, "hp_full_seconds", effective_max_hp)
    end

    def mp_per_tick
      recovery_rate(:fast_mana_regeneration, "mp_full_seconds", effective_max_mp)
    end

    def recovery_rate(skill, interval_key, maximum)
      config = Game::Combat::Calibration.config.fetch("recovery")
      factor = 1 + character.passive_skill_level(skill) / config.fetch("skill_divisor")
      fatigue = Characters::FatigueService.new(character:).current_percent(at: @clock.call)
      maximum.to_f / config.fetch(interval_key) * factor * Game::Combat::Calibration.fatigue_factor(fatigue)
    end
    private :recovery_rate

    # Calculate HP percentage
    #
    # @return [Float] HP as percentage (0-100)
    def hp_percent
      return 0 if effective_max_hp.zero?
      ((character.current_hp.to_f / effective_max_hp) * 100).round(1)
    end

    # Calculate MP percentage
    #
    # @return [Float] MP as percentage (0-100)
    def mp_percent
      return 0 if effective_max_mp.zero?
      ((character.current_mp.to_f / effective_max_mp) * 100).round(1)
    end

    # Returns a summary hash of character stats for display
    #
    # @return [Hash] stats summary with base stats and derived values
    def stats_summary
      stats = character.stats
      primary_breakdown = primary_stat_breakdown(stats)

      {
        current_hp: character.current_hp,
        max_hp: effective_max_hp,
        current_mp: character.current_mp,
        max_mp: effective_max_mp,
        strength: stats.get(:strength),
        dexterity: stats.get(:dexterity),
        luck: stats.get(:luck),
        intelligence: stats.get(:intelligence),
        vitality: stats.get(:vitality),
        attack_power: character.attack_power,
        defense: character.defense,
        crit_rate: character.critical_chance,
        primary_stats: primary_breakdown,
        combat_power_breakdown: character.combat_power_breakdown
      }
    end

    private

    def effective_max_hp
      return character.effective_max_hp if character.respond_to?(:effective_max_hp)

      character.max_hp
    end

    def effective_max_mp
      return character.effective_max_mp if character.respond_to?(:effective_max_mp)

      character.max_mp
    end

    def primary_stat_breakdown(stats)
      Character::PRIMARY_STATS.to_h do |stat|
        base = Character::BASE_PRIMARY_STATS.fetch(stat)
        allocated = character.allocated_stats.to_h[stat.to_s].to_i
        base_total = base + allocated
        total = stats.get(stat).to_i

        [
          stat,
          {
            base: base_total,
            equipment: total - base_total,
            total:
          }
        ]
      end
    end
  end
end
