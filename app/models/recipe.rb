# frozen_string_literal: true

class Recipe < ApplicationRecord
  SOURCE_KINDS = {
    quest: "quest",
    drop: "drop",
    vendor: "vendor",
    guild_research: "guild_research",
    tutorial: "tutorial"
  }.freeze unless const_defined?(:SOURCE_KINDS)

  RISK_LEVELS = {
    safe: "safe",
    moderate: "moderate",
    risky: "risky"
  }.freeze unless const_defined?(:RISK_LEVELS)

  STATION_ARCHETYPES = CraftingStation::ARCHETYPES unless const_defined?(:STATION_ARCHETYPES)

  enum :source_kind, SOURCE_KINDS, prefix: :source_kind
  enum :risk_level, RISK_LEVELS, prefix: :risk_level
  enum :required_station_archetype, STATION_ARCHETYPES, prefix: :station_archetype

  belongs_to :profession
  has_many :crafting_jobs, dependent: :restrict_with_exception

  validates :name, :tier, :duration_seconds, :output_item_name, presence: true
  validates :source_kind, inclusion: {in: SOURCE_KINDS.values}
  validates :risk_level, inclusion: {in: RISK_LEVELS.values}
  validates :required_station_archetype, inclusion: {in: STATION_ARCHETYPES.values}
  validates :premium_token_cost, numericality: {greater_than_or_equal_to: 0}

  def materials
    requirements.fetch("materials", {})
  end

  def requires_premium_tokens?
    premium_token_cost.positive?
  end

  def risky?
    risk_level == "risky"
  end

  def guild_locked?
    guild_bound?
  end

  def success_penalty
    requirements.fetch("success_penalty", 0).to_i
  end
end
