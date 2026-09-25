# frozen_string_literal: true

module Game
  module World
    # Soft-release Ashen fishing: per-fish hooks (наживка), tiered rods, and
    # fishing proficiency. Combat `ashen_bait` stays separate (bot ambush only).
    class FishingCatalog
      SKILL_KEY = "ashen_fishing"

      # fish_item_key => hook_key
      HOOKS = {
        "ash_perch" => "hook_worm",
        "shore_fish" => "hook_worm",
        "veil_eel" => "hook_bloodworm",
        "reef_fish" => "hook_bloodworm",
        "salt_carp" => "hook_dough",
        "ember_trout" => "hook_ember_fly",
        "drift_smelt" => "hook_crumb",
        "cinder_pike" => "hook_ember_fly",
        "mist_roach" => "hook_crumb",
        "veil_blackfin" => "hook_bloodworm",
        "glass_minnow" => "hook_crumb"
      }.freeze

      HOOK_LABELS = {
        "hook_worm" => ["Червь Угля", "Наживка для окуня / прибрежной рыбы."],
        "hook_bloodworm" => ["Кровавый червь", "Наживка для угря / рифа."],
        "hook_dough" => ["Соляное тесто", "Наживка для карпа."],
        "hook_ember_fly" => ["Угольная мушка", "Наживка для форели / щуки."],
        "hook_crumb" => ["Крошка дрейфа", "Наживка для корюшки / пескаря."]
      }.freeze

      # Shop buy prices (hooks). Catch sell must stay above these for raw-fish profit.
      HOOK_PRICES = {
        "hook_worm" => 3,
        "hook_bloodworm" => 5,
        "hook_dough" => 4,
        "hook_ember_fly" => 7,
        "hook_crumb" => 2
      }.freeze

      # Minimum ashen_fishing (+ rod bonus) for a guaranteed catch (no slip).
      SKILL_REQUIRED = {
        "ash_perch" => 0,
        "shore_fish" => 0,
        "mist_roach" => 3,
        "drift_smelt" => 5,
        "salt_carp" => 15,
        "veil_eel" => 25,
        "reef_fish" => 25,
        "cinder_pike" => 30,
        "ember_trout" => 40,
        "veil_blackfin" => 50,
        "glass_minnow" => 8
      }.freeze

      RODS = {
        "ashen_fishing_rod" => {tier: 1, skill_bonus: 0, speed_bonus: 0, price: 55, name: "Удочка Завесы"},
        "ashen_rod_ash" => {tier: 2, skill_bonus: 8, speed_bonus: 3, price: 120, name: "Удочка Угля"},
        "ashen_rod_salt" => {tier: 3, skill_bonus: 16, speed_bonus: 6, price: 220, name: "Удочка Соли"},
        "ashen_rod_veil" => {tier: 4, skill_bonus: 28, speed_bonus: 10, price: 400, name: "Удочка Разлома"}
      }.freeze

      # Junk sell prices — raw catch above hook cost so fishing pays without craft.
      FISH_SELL = {
        "ash_perch" => 9,
        "mist_roach" => 6,
        "veil_eel" => 16,
        "salt_carp" => 12,
        "ember_trout" => 22,
        "cinder_pike" => 18,
        "drift_smelt" => 5,
        "veil_blackfin" => 26,
        "glass_minnow" => 7
      }.freeze

      def self.hook_for_fish(fish_key)
        HOOKS[fish_key.to_s]
      end

      def self.skill_required_for(fish_key)
        SKILL_REQUIRED.fetch(fish_key.to_s, 10)
      end

      def self.best_rod(character)
        return nil unless character&.inventory

        owned = character.inventory.inventory_items.joins(:item_template)
          .where(item_templates: {key: RODS.keys})
          .includes(:item_template)
        return nil if owned.empty?

        owned.reject(&:broken?).map(&:item_template).max_by { |t| RODS.dig(t.key, :tier).to_i }
      end

      def self.gain_skill!(character)
        return unless character

        key = SKILL_KEY
        skills = character.passive_skills.to_h
        current = skills[key].to_i
        return if current >= 500

        character.update!(passive_skills: skills.merge(key => current + 1))
      end

      def self.raw_skill(character)
        character&.passive_skills.to_h[SKILL_KEY].to_i
      end

      def self.effective_skill(character, rod_key: nil)
        base = raw_skill(character)
        key = rod_key.presence || best_rod(character)&.key
        base + RODS.dig(key.to_s, :skill_bonus).to_i +
          Characters::TimedBuffs.new(character:).modifier("fishing_skill").to_i
      end

      def self.duration_seconds(base:, character:, rod_key: nil)
        skill = effective_skill(character, rod_key:)
        speed = RODS.dig(rod_key.to_s.presence || best_rod(character)&.key.to_s, :speed_bonus).to_i
        cut = [(skill / 10).floor + speed, (base * 0.55).floor].min
        [base - cut, 8].max
      end

      def self.guaranteed?(character, fish_key, rod_key: nil)
        effective_skill(character, rod_key:) >= skill_required_for(fish_key)
      end

      def self.slip_chance(character, fish_key, rod_key: nil)
        need = skill_required_for(fish_key)
        return 0.0 if need <= 0

        have = effective_skill(character, rod_key:)
        return 0.0 if have >= need

        ((need - have).to_f / need).clamp(0.05, 0.9)
      end

      def self.ensure_templates!
        HOOK_LABELS.each do |key, (name, description)|
          Game::Professions::Templates.send(:ensure_item!,
            key:,
            name:,
            item_type: "consumable",
            slot: "none",
            weight: 1,
            stack_limit: 50,
            base_price: HOOK_PRICES.fetch(key, 3),
            enhancement_rules: {
              "inventory_family" => "fishing",
              "subcategory" => "hooks",
              "source_name" => name,
              "description" => description,
              "fishing_hook" => true
            }
          )
        end

        RODS.each do |key, row|
          Game::Professions::Templates.send(:ensure_item!,
            key:,
            name: row[:name],
            item_type: "tool",
            slot: "none",
            weight: 2,
            stack_limit: 1,
            base_price: row[:price],
            durability_max: 40 + (row[:tier] * 10),
            enhancement_rules: {
              "inventory_family" => "things",
              "subcategory" => "tools",
              "source_name" => row[:name],
              "description" => "Удочка T#{row[:tier]}: +#{row[:skill_bonus]} к умелке, −#{row[:speed_bonus]}с к забросу; теряет 1 прочность за улов.",
              "gather_tool" => true,
              "fishing_rod" => true,
              "fishing_tier" => row[:tier],
              "fishing_skill_bonus" => row[:skill_bonus]
            }
          )
        end
      end
    end
  end
end
