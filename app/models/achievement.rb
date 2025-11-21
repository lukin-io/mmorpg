# frozen_string_literal: true

class Achievement < ApplicationRecord
  has_many :achievement_grants, dependent: :destroy

  validates :key, :name, presence: true
  validates :key, uniqueness: true
end
