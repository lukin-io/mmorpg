# frozen_string_literal: true

class HousingPlot < ApplicationRecord
  PLOT_TIERS = {
    "starter" => {storage_slots: 20, utility_slots: 1},
    "deluxe" => {storage_slots: 40, utility_slots: 2},
    "estate" => {storage_slots: 60, utility_slots: 3},
    "citadel" => {storage_slots: 80, utility_slots: 4}
  }.freeze

  enum :plot_tier, PLOT_TIERS.keys.index_with(&:to_s), prefix: :tier
  enum :visit_scope, {
    private: "private",
    friends: "friends",
    guild: "guild",
    public: "public"
  }, prefix: :visit_scope

  belongs_to :user
  belongs_to :visit_guild, class_name: "Guild", optional: true

  has_many :housing_decor_items, dependent: :destroy

  validates :plot_type, :location_key, :plot_tier, :exterior_style, :visit_scope, presence: true
  validates :upkeep_gold_cost, numericality: {greater_than: 0}
  validates :room_slots, :utility_slots, numericality: {greater_than: 0}
  validate :visit_guild_presence

  scope :showcased, -> { where(showcase_enabled: true) }

  before_validation :apply_tier_defaults

  def upkeep_due?
    next_upkeep_due_at.nil? || next_upkeep_due_at <= Time.current
  end

  def available_utility_slots
    utility_slots - housing_decor_items.utility.count
  end

  def showcase_payload
    {
      plot_type:,
      exterior_style:,
      trophies: housing_decor_items.trophy.limit(6).map { |decor| {name: decor.name, metadata: decor.metadata} }
    }
  end

  private

  def visit_guild_presence
    return unless visit_scope == "guild"
    errors.add(:visit_guild, "must be selected for guild visibility") unless visit_guild.present?
  end

  def apply_tier_defaults
    config = PLOT_TIERS[plot_tier] || PLOT_TIERS["starter"]
    self.storage_slots = config[:storage_slots] if storage_slots.to_i < config[:storage_slots]
    self.utility_slots = config[:utility_slots] if utility_slots.to_i < config[:utility_slots]
  end
end
