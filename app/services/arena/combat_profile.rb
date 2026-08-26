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

    def initialize(participation)
      @participation = participation
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
        "max_magic_mana" => magic_limit,
        "block_table" => block_table,
        "injected_attack_keys" => injected_attack_keys,
        "injected_block_keys" => injected_block_keys
      }
    end

    private

    attr_reader :participation

    def stored_profile
      @stored_profile ||= (participation&.metadata || {}).fetch(METADATA_KEY, {})
    end

    def match_profile
      @match_profile ||= (participation&.arena_match&.metadata || {}).fetch(METADATA_KEY, {})
    end

    def explicit_integer(key)
      value = explicit_profile_value(key, include_match: match_profile_applies_to_key?(key))
      integer_value(value)
    end

    def explicit_profile_value(key, include_match: true)
      string_key = key.to_s
      value = stored_profile[string_key]
      value = participation&.metadata&.dig(string_key) if value.blank?
      value = match_profile[string_key] if value.blank? && include_match
      value = participant_character&.metadata&.dig(METADATA_KEY, string_key) if value.blank?
      value = participant_character&.metadata&.dig(string_key) if value.blank?
      value
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
        explicit_item_seed || [DEFAULT_PHYSICAL_ATTACK_SEED + equipment_attack_cost_bonus, 1].max
      elsif participation&.npc?
        DEFAULT_PHYSICAL_ATTACK_SEED
      else
        DEFAULT_PHYSICAL_ATTACK_SEED
      end
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
        stats = item.item_template&.stat_modifiers.to_h
        item_value(
          stats["physical_attack_cost_seed"] ||
          stats[:physical_attack_cost_seed] ||
          stats["attack_cost_seed"] ||
          stats[:attack_cost_seed] ||
          item.properties&.dig("physical_attack_cost_seed") ||
          item.properties&.dig("attack_cost_seed")
        )
      end.max
    end

    def derived_block_table
      tables = equipped_items.filter_map { |item| explicit_item_block_table(item) }.uniq
      tables.one? ? tables.first : "normal"
    end

    def explicit_item_block_table(item)
      stats = item.item_template&.stat_modifiers.to_h
      value = stats["block_table"] || stats[:block_table] ||
        stats["shield_block_table"] || stats[:shield_block_table] ||
        item.properties&.dig("block_table") || item.properties&.dig("shield_block_table")
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
        stats = item.item_template&.stat_modifiers.to_h
        item_value(
          stats["physical_attack_cost_bonus"] ||
          stats[:physical_attack_cost_bonus] ||
          stats["attack_cost_bonus"] ||
          stats[:attack_cost_bonus] ||
          item.properties&.dig("physical_attack_cost_bonus") ||
          item.properties&.dig("attack_cost_bonus")
        ).to_i
      end
    end

    def item_value(value)
      integer_value(value)&.clamp(1, 250)
    end

    def equipped_items
      return [] unless participant_character&.inventory

      participant_character.inventory.inventory_items.equipped.includes(:item_template)
    end
  end
end
