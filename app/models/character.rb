# frozen_string_literal: true

class Character < ApplicationRecord
  MAX_NAME_LENGTH = 30

  belongs_to :user
  belongs_to :character_class, optional: true
  belongs_to :guild, optional: true
  belongs_to :clan, optional: true

  validates :name, presence: true, uniqueness: true, length: {maximum: MAX_NAME_LENGTH}
  validates :level, numericality: {greater_than: 0}
  validates :experience, numericality: {greater_than_or_equal_to: 0}

  validate :respect_character_limit, on: :create

  before_validation :inherit_memberships, on: :create

  private

  def inherit_memberships
    return unless user

    self.guild ||= user.primary_guild
    self.clan ||= user.primary_clan
  end

  def respect_character_limit
    return unless user

    if user.characters.count >= User::MAX_CHARACTERS
      errors.add(:base, "character limit reached")
    end
  end
end
