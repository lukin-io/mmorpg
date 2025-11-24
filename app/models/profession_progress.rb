# frozen_string_literal: true

class ProfessionProgress < ApplicationRecord
  PRIMARY_SLOT_LIMIT = 2
  GATHERING_SLOT_LIMIT = 2
  XP_BASE = 100
  XP_STEP = 35

  belongs_to :user
  belongs_to :character
  belongs_to :profession
  belongs_to :equipped_tool, class_name: "ProfessionTool", optional: true

  validates :skill_level, numericality: {greater_than: 0}
  validates :slot_kind, inclusion: {in: %w[primary gathering support]}

  before_validation :derive_user_from_character
  before_validation :assign_slot_kind

  validate :character_belongs_to_user
  validate :respect_slot_limits, on: :create

  scope :primary, -> { where(slot_kind: %w[primary support]) }
  scope :gathering, -> { where(slot_kind: "gathering") }

  def gain_experience!(amount)
    ApplicationRecord.transaction do
      new_experience = experience + amount
      new_level = skill_level

      while new_experience >= xp_threshold_for(new_level)
        new_experience -= xp_threshold_for(new_level)
        new_level += 1
      end

      update!(experience: new_experience, skill_level: new_level)
    end
  end

  def buff_bonus
    metadata.fetch("buff_bonus", 0).to_i
  end

  def location_bonus_for(zone)
    biome = zone&.biome
    case biome
    when "city"
      primary? ? 5 : 0
    when "forest"
      gathering? ? 10 : 0
    when "mountain"
      profession.name.match?(/smith/i) ? 8 : 2
    else
      0
    end
  end

  def gathering?
    slot_kind == "gathering"
  end

  def primary?
    slot_kind == "primary" || slot_kind == "support"
  end

  def available_tools
    character.profession_tools.where(profession:)
  end

  def best_tool
    equipped_tool || available_tools.order(quality_rating: :desc).first
  end

  private

  def xp_threshold_for(level)
    XP_BASE + (level * XP_STEP)
  end

  def derive_user_from_character
    self.user ||= character&.user
  end

  def assign_slot_kind
    self.slot_kind ||= profession&.slot_kind || "primary"
  end

  def respect_slot_limits
    return unless character && slot_kind

    total =
      if gathering?
        character.profession_progresses.gathering.count
      else
        character.profession_progresses.primary.count
      end

    limit = gathering? ? GATHERING_SLOT_LIMIT : PRIMARY_SLOT_LIMIT

    return if total < limit

    errors.add(:base, "Slot limit reached for #{slot_kind} professions")
  end

  def character_belongs_to_user
    return unless character && user
    return if character.user_id == user_id

    errors.add(:character, "must belong to the same user")
  end
end
