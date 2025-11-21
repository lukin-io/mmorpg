# frozen_string_literal: true

class NpcTemplate < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :level, numericality: {greater_than: 0}
  validates :role, presence: true
  validates :dialogue, presence: true
end
