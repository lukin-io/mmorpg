# frozen_string_literal: true

module Game
  module Combat
    # Pure, versioned approximation of the observed Neverlands inputs. Accepts
    # numeric attribute hashes; never queries records or rolls hidden RNGs.
    # The resolver supplies rolls, while the attributes adapter owns records.
    class Calibration
      def self.config
        @config ||= load(Rails.root.join("config/gameplay/combat_calibration.yml"))
      end

      def self.load(path)
        values = YAML.safe_load_file(path)
        raise ArgumentError, "Combat calibration must be an object" unless values.is_a?(Hash)

        validate_numbers!(values)
        %w[mastery_damage_divisor mastery_ap_divisor penetration_divisor resistance_divisor].each do |key|
          raise ArgumentError, "Combat calibration #{key} must be positive" unless values.fetch(key).positive?
        end
        %w[penetration_cap resistance_cap damage_variance fatigue_max_penalty].each do |key|
          raise ArgumentError, "Combat calibration #{key} must be a fraction" unless values.fetch(key).between?(0, 1)
        end
        [["recovery", "hp_full_seconds"], ["recovery", "mp_full_seconds"],
          ["recovery", "skill_divisor"], ["loot", "observation_scale"]].each do |section, key|
          raise ArgumentError, "Combat calibration #{section}.#{key} must be positive" unless values.fetch(section).fetch(key).positive?
        end
        weights = values["injuries"]["severity_weights"] if values["injuries"].is_a?(Hash)
        unless weights.is_a?(Hash) && weights.keys.sort == %w[heavy light medium] &&
            weights.values.all? { |weight| weight.is_a?(Integer) } && weights.values.sum == 100
          raise ArgumentError, "Combat calibration injury severity weights must contain light, medium and heavy integer percentages totaling 100"
        end
        JSON.parse(values.to_json, freeze: true)
      end

      def self.validate_numbers!(values)
        values.each do |key, value|
          if value.is_a?(Hash)
            validate_numbers!(value)
          elsif !value.is_a?(Numeric) || !value.finite? || !value.between?(0, 1_000_000)
            raise ArgumentError, "Combat calibration #{key} must be a bounded number"
          end
        end
      end

      def self.fatigue_factor(fatigue)
        excess = (fatigue.to_f - config.fetch("fatigue_threshold")).clamp(0, 50)
        1 - excess / 50 * config.fetch("fatigue_max_penalty")
      end

      # Ordinary defeat only: independent server rolls in 0...100 decide whether
      # an injury occurs and its severity. Returns nil or light/medium/heavy;
      # guaranteed timeout/combat injuries remain the awarder's responsibility.
      def self.injury_severity(risk:, chance_roll:, severity_roll:)
        return unless chance_roll < risk.to_i.clamp(0, 100)

        threshold = 0
        config.fetch("injuries").fetch("severity_weights").each do |severity, weight|
          threshold += weight
          return severity if severity_roll < threshold
        end
      end

      def self.attack(attributes)
        base = attributes.fetch(:base_attack, nil)
        base ||= attributes.fetch(:strength, 0) * config.fetch("strength_damage") + attributes.fetch(:weapon_damage, 0)
        base * (1 + attributes.fetch(:mastery, 0) / config.fetch("mastery_damage_divisor")) *
          attributes.fetch(:damage_multiplier, 1.0) * fatigue_factor(attributes.fetch(:fatigue, 0))
      end

      def self.damage(attacker:, defender:, action_multiplier:, body_multiplier:, critical:, variance:)
        penetration = (attacker.fetch(:penetration, 0) / config.fetch("penetration_divisor")).clamp(0, config.fetch("penetration_cap"))
        armor = defender.fetch(:armor, 0) * defender.fetch(:armor_multiplier, 1.0) *
          fatigue_factor(defender.fetch(:fatigue, 0)) * (1 - penetration)
        resistance = (defender.fetch(:resistance, 0) / config.fetch("resistance_divisor")).clamp(0, config.fetch("resistance_cap"))
        net = [attack(attacker) - armor, 0].max
        (net * action_multiplier * body_multiplier * (1 - resistance) * variance *
          (critical ? config.fetch("critical_multiplier") : 1)).round
      end

      # Saturating opposed ratings keep displayed modifiers above 100 useful
      # without treating them as literal probabilities.
      def self.opposed(left, right, scale: 35.0)
        scale * (left.to_f - right.to_f) / (left.to_f.abs + right.to_f.abs + 100)
      end
    end
  end
end
