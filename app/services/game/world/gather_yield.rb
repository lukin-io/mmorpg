# frozen_string_literal: true

module Game
  module World
    # Resolves dig / look / fish gather yields from authored tile resource_groups.
    # Soft-release trees/herbs/fish map to distinct craft materials (not Neverlands identity).
    class GatherYield
      TREE_YIELDS = {
        "pine" => "pine_resin",
        "tar_pine" => "pine_resin",
        "ash_oak" => "ash_oak_plank",
        "veil_willow" => "veil_willow_bark",
        "soot_birch" => "soot_birch_sap",
        "ember_cedar" => "ember_cedar_plank",
        "drift_alder" => "drift_alder_wood",
        "resin" => "wood_chips",
        "timber" => "wood_chips",
        "harvest" => "wood_chips"
      }.freeze

      HERB_YIELDS = {
        "herb" => "ash_herb",
        "ash_herb" => "ash_herb",
        "herbs" => "ash_herb",
        "forage" => "ash_herb",
        "dust_moss" => "dust_moss",
        "glow_lichen" => "glow_lichen",
        "ember_fern" => "ember_fern",
        "salt_sage" => "salt_sage",
        "veil_bloom" => "veil_bloom",
        "cinder_root" => "cinder_root",
        "tar_needle" => "tar_needle",
        "mist_leaf" => "mist_leaf",
        "nightshade_ash" => "nightshade_ash",
        "ember_cap" => "ember_cap",
        "silver_thistle" => "silver_thistle",
        "moon_orchid" => "moon_orchid",
        "berries" => "veil_bloom",
        "mushrooms" => "glow_lichen",
        "roots" => "cinder_root",
        "mist_herbs" => "mist_leaf"
      }.freeze

      FISH_YIELDS = {
        "shore_fish" => "ash_perch",
        "reef_fish" => "veil_eel",
        "ash_perch" => "ash_perch",
        "veil_eel" => "veil_eel",
        "salt_carp" => "salt_carp",
        "ember_trout" => "ember_trout",
        "drift_smelt" => "drift_smelt",
        "cinder_pike" => "cinder_pike",
        "mist_roach" => "mist_roach",
        "veil_blackfin" => "veil_blackfin",
        "glass_minnow" => "glass_minnow",
        "fish" => "ash_perch"
      }.freeze

      ORE_YIELDS = {
        "iron_ore" => "iron_ore",
        "silver_ore" => "silver_ore",
        "coal" => "coal_chunk",
        "crystal" => "ash_crystal",
        "scrap_ore" => "iron_ore",
        "stone" => "coal_chunk",
        "mine" => "iron_ore",
        "dig" => "coal_chunk",
        "ore" => "iron_ore"
      }.freeze

      RESPAWN_SECONDS = {
        "veil_bloom" => 20.minutes.to_i,
        "nightshade_ash" => 18.minutes.to_i,
        "ash_crystal" => 20.minutes.to_i,
        "silver_ore" => 18.minutes.to_i,
        "ember_trout" => 15.minutes.to_i,
        "cinder_pike" => 15.minutes.to_i
      }.freeze
      NIGHT_HERBS = %w[moon_orchid mist_leaf glow_lichen].freeze

      Result = Struct.new(:item_key, :quantity, :label, :group_key, :respawn_seconds, :depleted, keyword_init: true)

      def initialize(tile:, local_action_type:, character: nil, rng: Random.new, clock: -> { Time.current })
        @tile = tile
        @local_action_type = local_action_type.to_s
        @character = character
        @rng = rng
        @clock = clock
      end

      def call
        groups = Array(tile&.resource_groups).select { |g| g.is_a?(Hash) && g["active"] != false }
        case local_action_type
        when "digging"
          pick_from(groups, kinds: %w[tree wood resin harvest dig ore mine], fallback: "wood_chips", map: TREE_YIELDS.merge(ORE_YIELDS))
        when "resource_search"
          pick_from(groups, kinds: %w[herb plant moss forage], fallback: "ash_herb", map: HERB_YIELDS)
        when "fishing"
          pick_from(groups, kinds: %w[fish], fallback: "ash_perch", map: FISH_YIELDS)
        else
          nil
        end
      end

      private

      attr_reader :tile, :local_action_type, :character, :rng, :clock

      def pick_from(groups, kinds:, fallback:, map:)
        matching = groups.select { |g| kinds.include?(g["kind"].to_s) || map.key?(g["key"].to_s) }
        return nil if matching.empty?

        available = matching.reject { |group| depleted?(group) }
        return Result.new(depleted: true) if available.empty?

        group = weighted_groups(available, map:).sample(random: rng)
        key = map[group["key"].to_s] || map[group["kind"].to_s] || fallback
        qty = quantity_for(key)
        Result.new(
          item_key: key,
          quantity: qty,
          label: group["label"].presence || key,
          group_key: group["key"].to_s,
          respawn_seconds: RESPAWN_SECONDS.fetch(key, 10.minutes.to_i)
        )
      end

      # Soft profession bonus: +1 qty chance scales with skill (wiki miner/fisher depth
      # is richer; Ashen uses a bounded bonus so early shore stays readable).
      def profession_bonus_chance
        return 0 unless character

        skills = character.metadata.to_h.fetch("profession_skills", {})
        skill = case local_action_type
        when "digging" then skills["miner"].to_i + skills["tar_smith"].to_i / 2
        when "resource_search" then skills["herbalist"].to_i + skills["ash_healer"].to_i / 2
        when "fishing" then skills["ashen_fishing"].to_i
        else 0
        end
        [[skill / 25, 0].max, 4].min
      end

      def depleted?(group)
        value = tile.metadata.to_h.dig("resource_depletion", group["key"].to_s)
        expires_at = Time.zone.parse(value.to_s)
        expires_at.present? && expires_at > clock.call
      rescue ArgumentError, TypeError
        false
      end

      def weighted_groups(groups, map:)
        multiplier = weather_weight_multiplier
        return groups if multiplier <= 1

        # Duplicating nocturnal/dusk entries changes only seeded selection weight.
        groups.flat_map do |group|
          key = map[group["key"].to_s] || map[group["kind"].to_s]
          NIGHT_HERBS.include?(key) ? ([group] * multiplier) : [group]
        end
      end

      def weather_weight_multiplier
        hour = clock.call.in_time_zone.hour
        return 2 if hour >= 20 || hour <= 5 # night
        return 2 if hour.between?(5, 7) || hour.between?(18, 20) # dawn/dusk
        1
      end

      def night?
        hour = clock.call.in_time_zone.hour
        hour >= 20 || hour <= 5
      end

      def quantity_for(key)
        base = case key
        when "wood_chips", "ash_herb", "drift_smelt", "mist_roach" then rng.rand(1..2)
        else 1
        end
        bonus = profession_bonus_chance
        return base if bonus <= 0

        base + (rng.rand(100) < (bonus * 12) ? 1 : 0)
      end
    end
  end
end
