# frozen_string_literal: true

class Title < ApplicationRecord
  has_many :title_grants, dependent: :destroy
  has_many :users, through: :title_grants

  validates :name, :requirement_key, presence: true
end
