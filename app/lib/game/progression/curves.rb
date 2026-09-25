# frozen_string_literal: true

module Game
  module Progression
    # Soft-release Ashen XP curves. Thresholds are formula-driven; level rewards
    # (stat/perk/NV/caps) stay in character_progression.yml via Catalog.
    module Curves
      module_function

      # XP required to advance from +level+ to level+1.
      # Polynomial uses (level + 1) so L0→1 is never a free rung.
      def xp_to_advance(level)
        n = [level.to_i, 0].max + 1
        (n**3) * 10 + (n**2) * 50 + (n * 100)
      end

      # Cumulative combat XP needed to reach +target_level+ (0 => 0).
      def cumulative_threshold(target_level)
        target = target_level.to_i
        return 0 if target <= 0

        (0...target).sum { |level| xp_to_advance(level) }
      end

      # Base monster XP scaled by absolute level gap (floor 10% when |Δ| ≥ 9).
      def monster_xp(monster_level:, player_level:)
        monster = [monster_level.to_i, 1].max
        player = [player_level.to_i, 0].max
        base = monster * 15
        factor = [1.0 - ((player - monster).abs * 0.1), 0.1].max
        (base * factor).round
      end
    end
  end
end
