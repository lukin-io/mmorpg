# frozen_string_literal: true

module Characters
  # Persists and resolves expiring character modifiers in character metadata.
  class TimedBuffs
    METADATA_KEY = "active_buffs"
    DEFAULT_DURATION = 1.hour.to_i

    def initialize(character:, clock: -> { Time.current })
      @character = character
      @clock = clock
    end

    BLOOD_I_SET_KEY = "blood_i_triad"
    BLOOD_I_SET_MODS = {"attack" => 5, "defense" => 5}.freeze

    def apply!(key:, label:, mods:, duration_seconds: DEFAULT_DURATION, blood_tier: nil)
      now = clock.call
      entry = {
        "key" => key.to_s,
        "label" => label.to_s,
        "expires_at" => (now + duration_seconds.to_i).iso8601,
        "mods" => normalize_mods(mods)
      }
      entry["blood_tier"] = blood_tier.to_i if blood_tier.present?

      character.with_lock do
        character.reload
        retained = stored_buffs.select do |buff|
          active?(buff, now:) &&
            buff["key"].to_s != entry["key"] &&
            buff["key"].to_s != BLOOD_I_SET_KEY &&
            !(entry["blood_tier"] == 3 && buff["blood_tier"].to_i == 3)
        end
        persist!(with_blood_i_set(retained << entry, now:))
      end
      entry
    end

    def active
      now = clock.call
      current = stored_buffs
      retained = current.select { |buff| active?(buff, now:) }
      persist!(retained) if retained.size != current.size
      retained
    end

    def modifier(key)
      active.sum { |buff| buff.fetch("mods", {}).fetch(key.to_s, 0).to_f }
    end

    private

    attr_reader :character, :clock

    def stored_buffs
      Array(character.metadata.to_h[METADATA_KEY]).filter_map do |buff|
        buff.deep_stringify_keys if buff.is_a?(Hash)
      end
    end

    def active?(buff, now:)
      expires_at = Time.zone.parse(buff["expires_at"].to_s)
      expires_at.present? && expires_at > now
    rescue ArgumentError, TypeError
      false
    end

    def normalize_mods(mods)
      mods.to_h.each_with_object({}) do |(key, value), normalized|
        number = Float(value, exception: false)
        normalized[key.to_s] = number if number
      end
    end

    def with_blood_i_set(buffs, now:)
      blood_i = buffs
        .select { |buff| buff["blood_tier"].to_i == 1 && active?(buff, now:) }
        .uniq { |buff| buff["key"].to_s }
      return buffs if blood_i.size < 3

      expires_at = blood_i.filter_map { |buff| Time.zone.parse(buff["expires_at"].to_s) }.min
      buffs << {
        "key" => BLOOD_I_SET_KEY,
        "label" => I18n.t("game.inventory.blood_i_set", default: "Комплект Крови I"),
        "expires_at" => expires_at.iso8601,
        "mods" => BLOOD_I_SET_MODS
      }
    end

    def persist!(buffs)
      character.update_column(:metadata, character.metadata.to_h.merge(METADATA_KEY => buffs))
    end
  end
end
