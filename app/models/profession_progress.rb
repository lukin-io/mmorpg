# frozen_string_literal: true

class ProfessionProgress < ApplicationRecord
  belongs_to :user
  belongs_to :profession

  validates :skill_level, numericality: {greater_than: 0}

  def gain_experience!(amount)
    increment!(:experience, amount)
  end
end
