# frozen_string_literal: true

module Arena
  # Builds the per-participant combat budget used by Neverlands-style fights.
  #
  # Neverlands sends these numbers in the fight payload (`fight_pm[1]` for AP
  # and `fight_pm[2]` for the physical attack seed). Rails stores the local
  # equivalent in ArenaParticipation metadata so every turn submission validates
  # against the same profile after reloads and ActionCable reconnects.
  class CombatProfile
    METADATA_KEY = "combat_profile"
    DEFAULT_AP_LIMIT = Game::Combat::ActionCatalog::DEFAULT_AP_PER_TURN
    DEFAULT_PHYSICAL_ATTACK_SEED = Game::Combat::ActionCatalog.attack_cost(:simple)
    AIMED_ATTACK_SURCHARGE = 20

    class << self
      # Current equipment preview for Profile/Inventory, without creating or
      # persisting a participation. The next fight uses these same rules.
      def for_character(character)
        new(nil, character:).to_h
      end

      def for_participation(participation, persist: false)
        profile = new(participation).to_h
        persist!(participation, profile) if persist
        profile
      end

      def persist!(participation, profile = nil)
        return {} unless participation

        profile ||= new(participation).to_h
        metadata = participation.metadata || {}
        return profile if metadata[METADATA_KEY] == profile

        participation.update!(metadata: metadata.merge(METADATA_KEY => profile))
        profile
      end

      def ap_limit(participation)
        for_participation(participation).fetch("ap_limit")
      end

      def physical_attack_seed(participation)
        for_participation(participation).fetch("physical_attack_cost_seed")
      end

      def attack_cost(participation, action_key)
        case action_key.to_s
        when "simple" then physical_attack_seed(participation)
        when "aimed" then physical_attack_seed(participation) + AIMED_ATTACK_SURCHARGE
        else
          Game::Combat::ActionCatalog.attack_cost(action_key)
        end
      end
    end

    def initialize(participation, character: nil)
      @participation = participation
      @participant_character = character
    end

    def to_h
      seed = explicit_integer("physical_attack_cost_seed") ||
        explicit_integer("simple_attack_cost") ||
        derived_physical_attack_seed
      ap_limit = explicit_integer("ap_limit") ||
        explicit_integer("action_points_per_turn") ||
        derived_ap_limit
      magic_limit = explicit_integer("max_magic_mana") ||
        explicit_integer("magic_mana_limit") ||
        derived_magic_mana_limit
      block_table = Game::Combat::ActionCatalog.normalize_block_table(
        explicit_profile_value("block_table") || derived_block_table
      )

      {
        "ap_limit" => ap_limit,
        "physical_attack_cost_seed" => seed,
        "simple_attack_cost" => seed,
        "aimed_attack_cost" => seed + AIMED_ATTACK_SURCHARGE,
        "max_magic_mana" => physical_only? ? 0 : magic_limit,
        "block_table" => block_table,
        "injected_attack_keys" => physical_only? ? [] : injected_attack_keys,
        "injected_block_keys" => physical_only? ? [] : injected_block_keys
      }
    end

    private

    attr_reader :participation

    def physical_only?
      participation&.arena_match&.metadata.to_h["physical_only"] == true
    end

    def stored_profile
      @stored_profile ||= (participation&.metadata || {}).fetch(METADATA_KEY, {})
    end

    def match_profile
      @match_profile ||= (participation&.arena_match&.metadata || {}).fetch(METADATA_KEY, {})
    end

    def explicit_integer(key)
      integer_value(explicit_profile_value(key))
    end

    def explicit_profile_value(key)
      string_key = key.to_s
      # Presence selects the authoritative layer: an explicit empty action list
      # disables inherited actions, including after a fight profile is persisted.
      return stored_profile[string_key] if stored_profile&.key?(string_key)

      participation_metadata = participation&.metadata.to_h
      return participation_metadata[string_key] if participation_metadata.key?(string_key)

      if participation&.npc?
        npc_profile = participation.npc_combat_data[METADATA_KEY]
        return npc_profile[string_key] if npc_profile&.key?(string_key)
      end
      if match_profile_applies_to_key?(string_key) && match_profile&.key?(string_key)
        return match_profile[string_key]
      end

      character_metadata = participant_character&.metadata.to_h
      character_profile = character_metadata[METADATA_KEY]
      return character_profile[string_key] if character_profile&.key?(string_key)

      # The character's root block_table describes its last defensive stance,
      # not the equipment profile for a new fight. Explicit profile overrides
      # remain in combat_profile; otherwise current equipment selects the tier.
      character_metadata[string_key] unless string_key == "block_table"
    end

    def match_profile_applies_to_key?(key)
      return true unless participation&.npc?

      %w[ap_limit action_points_per_turn max_magic_mana magic_mana_limit].include?(key.to_s)
    end

    def integer_value(value)
      return nil if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def derived_ap_limit
      if participant_character
        participant_character.max_action_points.to_i
      else
        DEFAULT_AP_LIMIT
      end
    end

    def derived_physical_attack_seed
      if participant_character
        explicit_item_seed || derived_weapon_cost
      elsif participation&.npc?
        DEFAULT_PHYSICAL_ATTACK_SEED
      else
        DEFAULT_PHYSICAL_ATTACK_SEED
      end
    end

    def derived_weapon_cost
      weapons = participant_character.combat_weapons
      config = Game::Combat::Calibration.config
      costs = weapons.map do |weapon|
        base = integer_value(weapon.item_template.requirements["ap"]) || DEFAULT_PHYSICAL_ATTACK_SEED
        base - (participant_character.weapon_mastery_for(weapon) / config.fetch("mastery_ap_divisor")).floor
      end
      costs = [DEFAULT_PHYSICAL_ATTACK_SEED - (participant_character.weapon_mastery / config.fetch("mastery_ap_divisor")).floor] if costs.empty?
      combined = (costs.sum.to_f / costs.size).round
      combined += config.fetch("dual_weapon_ap_surcharge") if weapons.size > 1
      [combined + equipment_attack_cost_bonus, 1].max
    end

    def derived_magic_mana_limit
      return participant_character.max_mp.to_i if participant_character

      0
    end

    def participant_character
      @participant_character ||= participation&.character
    end

    def explicit_item_seed
      equipped_items.filter_map do |item|
        value = explicit_item_value(item, "physical_attack_cost_seed", "attack_cost_seed")
        integer_value(value)&.clamp(1, 250)
      end.max
    end

    def derived_block_table
      tables = equipped_items.filter_map { |item| explicit_item_block_table(item) }.uniq
      tables.one? ? tables.first : "normal"
    end

    def explicit_item_block_table(item)
      value = explicit_item_value(item, "block_table", "shield_block_table")
      table = Game::Combat::ActionCatalog.normalize_block_table(value)

      table unless table == "normal"
    end

    def injected_block_keys
      Array(explicit_profile_value("injected_block_keys")).map(&:to_s).uniq.select do |key|
        Game::Combat::ActionCatalog.block_config(key)["block_table"] == "magic"
      end
    end

    def injected_attack_keys
      Array(explicit_profile_value("injected_attack_keys")).map(&:to_s).uniq.select do |key|
        Game::Combat::ActionCatalog.attack_config(key).present? &&
          !Game::Combat::ActionCatalog::PHYSICAL_ATTACK_KEYS.include?(key)
      end
    end

    def equipment_attack_cost_bonus
      equipped_items.sum do |item|
        # Bonuses are signed adjustments, not positive absolute attack seeds.
        integer_value(explicit_item_value(item, "physical_attack_cost_bonus", "attack_cost_bonus")).to_i
      end
    end

    def explicit_item_value(item, *keys)
      [item.effect_modifiers, item.properties.to_h].each do |source|
        keys.each do |key|
          return source[key] if source.key?(key)
          return source[key.to_sym] if source.key?(key.to_sym)
        end
      end
      nil
    end

    def equipped_items
      return [] unless participant_character&.inventory

      participant_character.inventory.inventory_items.equipped.includes(:item_template)
    end
  end
end
