# frozen_string_literal: true

class Recipe < ApplicationRecord
  unless defined?(SOURCE_KINDS)
    SOURCE_KINDS = {
      drop: "drop",
      vendor: "vendor"
    }.freeze
  end

  unless defined?(RISK_LEVELS)
    RISK_LEVELS = {
      safe: "safe",
      moderate: "moderate",
      risky: "risky"
    }.freeze
  end

  STATION_ARCHETYPES = CraftingStation::ARCHETYPES unless defined?(STATION_ARCHETYPES)

  enum :source_kind, SOURCE_KINDS, prefix: :source_kind
  enum :risk_level, RISK_LEVELS, prefix: :risk_level
  enum :required_station_archetype, STATION_ARCHETYPES, prefix: :station_archetype

  belongs_to :profession
  has_many :crafting_jobs, dependent: :restrict_with_exception

  validates :name, :tier, :duration_seconds, :output_item_name, presence: true
  validates :source_kind, inclusion: {in: SOURCE_KINDS.values}
  validates :risk_level, inclusion: {in: RISK_LEVELS.values}
  validates :required_station_archetype, inclusion: {in: STATION_ARCHETYPES.values}

  def materials
    requirements.fetch("materials", {})
  end

  def required_skill_level
    requirements.fetch("skill_level", tier * 10)
  end

  def risky?
    risk_level == "risky"
  end

  def success_penalty
    requirements.fetch("success_penalty", 0).to_i
  end
end
