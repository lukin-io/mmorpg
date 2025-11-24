# frozen_string_literal: true

# ProfessionTool tracks tool quality/durability per character and profession.
class ProfessionTool < ApplicationRecord
  belongs_to :character
  belongs_to :profession

  scope :equipped, -> { where(equipped: true) }

  validates :tool_type, presence: true
  validates :quality_rating, numericality: {greater_than_or_equal_to: 0}
  validates :durability, :max_durability, numericality: {greater_than_or_equal_to: 0}

  before_save :clamp_durability

  def broken?
    durability <= 0
  end

  def degrade!(amount)
    update!(durability: (durability - amount).clamp(0, max_durability))
  end

  def repair!(amount: max_durability)
    update!(
      durability: (durability + amount).clamp(0, max_durability)
    )
  end

  private

  def clamp_durability
    return unless durability && max_durability

    self.durability = durability.clamp(0, max_durability)
  end
end
