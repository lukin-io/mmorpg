# frozen_string_literal: true

require "yaml"

module Game
  module Combat
    # Read-only combat limits for one trusted entitlement at one server instant.
    # No entitlement lookup, persistence, purchases, or earned-XP calculation.
    class PremiumBenefits
      CONFIG_PATH = File.expand_path("../../../../config/gameplay/combat_benefits.yml", __dir__)
      COMBAT_TIERS = %w[premium gold vip].freeze
      STANDARD_BENEFITS = {"drop_level_window" => 2, "experience_cap_multiplier" => 1.0}.freeze
      CONFIG = begin
        raw = YAML.safe_load_file(CONFIG_PATH, aliases: false)
        raw.is_a?(Hash) ? raw.transform_values(&:freeze).freeze : {}.freeze
      rescue Psych::Exception, Errno::ENOENT
        {}.freeze
      end

      # tier: exact lowercase String/Symbol from a trusted server entitlement.
      # expires_at: Time (including Rails TimeWithZone); nil/invalid means inactive.
      # now: required server Time snapshot, never a client timestamp. Entitlements
      # are active only while expires_at > now. Construct again at each decision;
      # this object intentionally retains its original evaluation instant.
      def initialize(tier: nil, expires_at: nil, now:)
        raise ArgumentError, "now must be a server Time" unless now.is_a?(Time)

        @benefits = benefits_for(tier, expires_at, now)
      end

      # Returns an inclusive Integer Range of eligible NPC levels, bounded at 0.
      # player_level must be a non-negative Integer from authoritative state.
      def drop_level_range(player_level:)
        validate_non_negative_integer!(player_level, "player_level")
        window = @benefits.fetch("drop_level_window")
        [player_level - window, 0].max..(player_level + window)
      end

      # Returns the largest Integer XP maximum allowed by the adjusted cap.
      # base_cap is the non-negative Integer from the existing level catalog.
      # Only the cap is multiplied; callers still use min(earned_xp, maximum).
      def maximum_experience(base_cap:)
        validate_non_negative_integer!(base_cap, "base_cap")
        multiplier = Rational(@benefits.fetch("experience_cap_multiplier").to_s)
        (base_cap * multiplier).floor
      end

      private

      def benefits_for(tier, expires_at, now)
        return STANDARD_BENEFITS unless tier.is_a?(String) || tier.is_a?(Symbol)
        return STANDARD_BENEFITS unless COMBAT_TIERS.include?(tier.to_s)
        return STANDARD_BENEFITS unless expires_at.is_a?(Time) && expires_at > now

        row = CONFIG[tier.to_s]
        valid_benefits?(row) ? row : STANDARD_BENEFITS
      end

      # Invalid/missing configured tiers cannot widen the standard contract.
      # Values stay within the captured total windows and cap multipliers.
      def valid_benefits?(row)
        return false unless row.is_a?(Hash)

        window = row["drop_level_window"]
        multiplier = row["experience_cap_multiplier"]
        window.is_a?(Integer) && [2, 4, 6].include?(window) &&
          (multiplier.is_a?(Integer) || multiplier.is_a?(Float)) &&
          [1.0, 1.5, 2.0, 2.5].include?(multiplier)
      end

      def validate_non_negative_integer!(value, name)
        return if value.is_a?(Integer) && value >= 0

        raise ArgumentError, "#{name} must be a non-negative Integer"
      end
    end
  end
end
