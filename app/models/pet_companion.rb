# frozen_string_literal: true

class PetCompanion < ApplicationRecord
  AFFINITY_THRESHOLDS = {
    "neutral" => 0,
    "friendly" => 150,
    "bonded" => 400,
    "legendary" => 800
  }.freeze

  enum :affinity_stage, AFFINITY_THRESHOLDS.keys.index_with(&:to_s)

  belongs_to :user
  belongs_to :pet_species

  validates :level, numericality: {greater_than_or_equal_to: 1}
  validates :bonding_experience, numericality: {greater_than_or_equal_to: 0}
  validates :gathering_bonus, numericality: {greater_than_or_equal_to: 0}

  scope :ready_for_care, -> { where("care_task_available_at IS NULL OR care_task_available_at <= ?", Time.current) }

  def care_available?
    care_task_available_at.blank? || care_task_available_at <= Time.current
  end

  def apply_care!(task_key:, bonding_xp: 50, cooldown_minutes: 60)
    update!(
      bonding_experience: bonding_experience + bonding_xp,
      care_state: care_state.merge("last_task" => task_key),
      care_task_available_at: Time.current + cooldown_minutes.minutes,
      affinity_stage: affinity_stage_for(bonding_experience + bonding_xp)
    )
  end

  def passive_bonuses
    Companions::BonusCalculator.new(pet: self).call
  end

  private

  def affinity_stage_for(total_xp)
    AFFINITY_THRESHOLDS.sort_by { |_stage, threshold| threshold }.reverse_each do |stage, threshold|
      return stage if total_xp >= threshold
    end
    "neutral"
  end
end
