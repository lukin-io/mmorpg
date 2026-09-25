# frozen_string_literal: true

module Game
  module Combat
    # Player-facing combat coefficient sheet (Mist-style handbook math).
    # Reads the same YAML the arena resolver uses — no second truth.
    class PublicSheet
      def self.table
        Arena::CombatResolver.resolution_table
      end

      def self.bullets(locale: I18n.locale)
        t = table
        ru = locale.to_s.start_with?("ru")
        [
          ru ? "База попадания #{t[:base_hit_chance]}%, блока #{t[:base_block_chance]}%. Уворот и крит — по формулам Ashen (см. ниже)." :
            "Base hit #{t[:base_hit_chance]}%, block #{t[:base_block_chance]}%. Evasion/crit use Ashen formulas below.",
          ru ? "Крит ×#{t[:critical_multiplier]} к base_hit до брони. Мин. урон #{t[:min_damage]}." :
            "Crit ×#{t[:critical_multiplier]} on base_hit before armor. Min damage #{t[:min_damage]}.",
          ru ? "Попадание: +Точность×#{t.dig(:hit_chance, :accuracy)}, +Ловк×#{t.dig(:hit_chance, :dexterity)}; −Уловка×#{t.dig(:hit_chance, :defender_evasion)}." :
            "Hit: +Accuracy×#{t.dig(:hit_chance, :accuracy)}, +Dex×#{t.dig(:hit_chance, :dexterity)}; −Evasion×#{t.dig(:hit_chance, :defender_evasion)}.",
          ru ? "Уворот: (Уловка×#{t.dig(:evasion_chance, :evasion)} − Точность×#{t.dig(:evasion_chance, :attacker_accuracy)}), кап #{t.dig(:evasion_chance, :min)}–#{t.dig(:evasion_chance, :max)}%." :
            "Evasion: (Evasion×#{t.dig(:evasion_chance, :evasion)} − Accuracy×#{t.dig(:evasion_chance, :attacker_accuracy)}), cap #{t.dig(:evasion_chance, :min)}–#{t.dig(:evasion_chance, :max)}%.",
          ru ? "Крит: (Удача×#{t.dig(:crit_chance, :luck)} + Ловк×#{t.dig(:crit_chance, :dexterity)}), кап #{t.dig(:crit_chance, :min)}–#{t.dig(:crit_chance, :max)}%." :
            "Crit: (Luck×#{t.dig(:crit_chance, :luck)} + Dex×#{t.dig(:crit_chance, :dexterity)}), cap #{t.dig(:crit_chance, :min)}–#{t.dig(:crit_chance, :max)}%.",
          ru ? "Урон: base_hit ∈ [АТК×0.6 … АТК×1.3], затем max(урон − защита, #{t[:min_damage]})." :
            "Damage: base_hit ∈ [ATK×0.6 … ATK×1.3], then max(damage − defense, #{t[:min_damage]}).",
          ru ? "Блок: +Защита×#{t.dig(:block_chance, :defense)}; кап #{t.dig(:block_chance, :max)}%." :
            "Block: +Defense×#{t.dig(:block_chance, :defense)}; cap #{t.dig(:block_chance, :max)}%."
        ]
      end
    end
  end
end
