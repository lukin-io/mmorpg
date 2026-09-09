# frozen_string_literal: true

module Manage
  # Converts the NPC editor's bounded roster/member rows into TileNpc metadata.
  # Unedited sample/member metadata is retained by stable sample key and member
  # index. The existing model and mutation service validate and audit the result.
  class TileNpcAttributes
    def initialize(attributes:, npc:)
      @attributes = attributes.deep_dup
      @npc = npc
    end

    def call
      metadata = attributes.fetch("metadata")
      if attributes.key?("active")
        metadata["active"] = boolean(attributes.delete("active"))
      end
      return attributes unless attributes.delete("content_fields") == "1"

      metadata["encounter_count"] = integer(attributes.delete("encounter_count"))
      rosters = attributes.delete("rosters").to_h.values.filter_map { |sample| normalize_sample(sample.to_h) }
      rosters.any? ? metadata["encounter_rosters"] = rosters : metadata.delete("encounter_rosters")
      attributes
    end

    private

    attr_reader :attributes, :npc

    def normalize_sample(submitted)
      return if submitted["key"].blank? && submitted.fetch("members", {}).to_h.values.all? { |member| member.to_h.values.all?(&:blank?) }

      existing = npc.encounter_roster_samples.find { |sample| sample["key"] == submitted["key"] } || {}
      sample = existing.merge("key" => submitted["key"])
      %w[weight encounter_experience_reward trauma_percent].each do |key|
        submitted[key].present? ? sample[key] = integer(submitted[key]) : sample.delete(key)
      end
      sample["members"] = submitted.fetch("members", {}).to_h.values.each_with_index.filter_map do |raw, index|
        member = raw.to_h
        next if member.values.all?(&:blank?)

        prior = Array(existing["members"])[index].to_h
        prior = {} unless prior["npc_key"] == member["npc_key"]
        normalized = prior.except("level", "level_min", "level_max", "hp").merge("npc_key" => member["npc_key"])
        %w[level level_min level_max hp].each { |key| normalized[key] = integer(member[key]) if member[key].present? }
        normalized
      end
      sample
    end

    def integer(value)
      return value if value.is_a?(Integer)
      return Integer(value, exception: false) if value.is_a?(String) && value.match?(/\A\d+\z/)

      value
    end

    def boolean(value)
      return true if [true, "1"].include?(value)
      return false if [false, "0"].include?(value)

      value
    end
  end
end
