# frozen_string_literal: true

class Recipe < ApplicationRecord
  belongs_to :profession
  has_many :crafting_jobs, dependent: :restrict_with_exception

  validates :name, :tier, :duration_seconds, :output_item_name, presence: true
end
