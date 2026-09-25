# frozen_string_literal: true

module Game
  module World
    # Equips an Ashen wilderness NPC with one thematic set matching its world tier
    # and derives combat attack/defense/HP from the worn pieces (server-authoritative).
    # Soft-release: four Mist-guided archetypes (tank/evader/critter/mage) scale the
    # floor so shore/farm bots ask for different player answers (STR/ACC/DEF/MR).
    class NpcLoadout
      SET_IDS = %w[blood demiurge distortion judge swamp].freeze
      # Universe freeze: world bands 1..23 plus endgame catalog steps through 50.
      # 5 sets × 10 pieces × 29 tiers = 1450 set ItemTemplates (≥650 requirement).
      CATALOG_TIERS = ((1..23).to_a + [25, 30, 35, 40, 45, 50]).uniq.sort.freeze
      PIECE_SUFFIXES = %w[
        weapon-sword helm armor-plate gloves bracers boots amulet ring earring-1 waist
      ].freeze

      Result = Struct.new(:item_keys, :combat_stats, :set_id, :set_tier, :archetype, keyword_init: true)

      def initialize(npc_template:, world_tier: nil, rng: Random.new)
        @npc_template = npc_template
        @world_tier = (world_tier || npc_template.metadata.to_h["world_tier"] || 1).to_i
        @rng = rng
      end

      def call
        archetype = NpcCombatArchetypes.archetype_for(npc_template)
        profile = NpcCombatArchetypes.profile(archetype)
        set_id = pick_set_id(profile)
        set_tier = catalog_tier_for(world_tier)
        keys = PIECE_SUFFIXES.map { |suffix| "set-#{set_id}-#{suffix}-t#{set_tier}" }
        templates = ItemTemplate.where(key: keys).index_by(&:key)
        present = keys.select { |key| templates.key?(key) }
        present = keys if present.empty?

        Result.new(
          item_keys: present,
          combat_stats: derive_stats(templates.values_at(*present).compact, profile),
          set_id:,
          set_tier:,
          archetype:
        )
      end

      def self.catalog_tier_for(world_tier)
        # Personal-instance wilderness bands map onto seeded set keys.
        # Soft-launch: early shore (bands 1–8) uses lower set tiers so shop
        # armor matters without one-shotting starters (Mist/Legend early curve).
        band = world_tier.to_i.clamp(1, 23)
        return [1, (band / 2.0).ceil].max if band <= 8

        band
      end

      def self.drop_chance_percent(role:, set_tier:)
        base = case role.to_s
        when "boss" then 4.0
        when "elite" then 2.5
        else 1.5
        end
        # Higher catalog tiers are scarcer.
        rarity_scale = case set_tier.to_i
        when 40..50 then 0.25
        when 25..39 then 0.45
        when 15..24 then 0.7
        when 10..14 then 0.85
        else 1.0
        end
        (base * rarity_scale).clamp(0.15, 5.0).round(2)
      end

      private

      attr_reader :npc_template, :world_tier, :rng

      def catalog_tier_for(tier)
        self.class.catalog_tier_for(tier)
      end

      def pick_set_id(profile)
        focus = Array(profile["set_focus"]).map(&:to_s) & SET_IDS
        focus = SET_IDS if focus.empty?
        focus.fetch(rng.rand(focus.length))
      end

      def derive_stats(templates, profile)
        level = npc_template.level.to_i.clamp(1, 100)
        # Smooth Mist-style floor: grows with level, then archetype mults specialize.
        attack = 10 + (level * 5)
        defense = 12 + (level * 5)
        hp = 80 + (level * 26) + ((level * level) / 5)
        agility = 3 + level
        accuracy = 4 + (level * 2)
        luck = 1 + (level / 2)
        magic_power = 4 + (level * 3)

        set_scale = case world_tier.to_i
        when 0..6 then 0.12
        when 7..10 then 0.45
        else 1.0
        end

        templates.each do |template|
          mods = template.stat_modifiers.to_h
          dmin = mods["damage_min"].to_i
          dmax = mods["damage_max"].to_i
          if dmax.positive?
            attack += (((dmin + dmax) / 2.0) * set_scale).round
          end
          defense += ((mods["armor_class"].to_i + mods["defense"].to_i + mods["armor"].to_i) * set_scale).round
          hp += (mods["hp"].to_i * set_scale).round
          agility += ((mods["evasion"].to_i + mods["dexterity"].to_i) * set_scale).round
          accuracy += (mods["accuracy"].to_i * set_scale).round
          luck += (mods["luck"].to_i * set_scale).round
          attack += (mods["strength"].to_i * set_scale).round
          magic_power += (
            (mods["magic_power"].to_i + mods["intelligence"].to_i + mods["spell_power"].to_i) * set_scale
          ).round
        end

        {
          "attack" => scale(attack, profile["attack_mult"]),
          "defense" => scale(defense, profile["defense_mult"]),
          "hp" => [scale(hp, profile["hp_mult"]), 40].max,
          "agility" => scale(agility, profile["agility_mult"]),
          "accuracy" => scale(accuracy, profile["accuracy_mult"]),
          "luck" => scale(luck, profile["luck_mult"]),
          "magic_power" => scale(magic_power, profile["magic_power_mult"]),
          "magic_resist" => profile["magic_resist"].to_i,
          "combat_archetype" => profile["key"],
          "crit_chance" => 0,
          "dodge_chance" => 0
        }
      end

      def scale(value, mult)
        [(value * mult.to_f).round, 0].max
      end
    end
  end
end
