# frozen_string_literal: true

class Title < ApplicationRecord
  validates :name, :requirement_key, presence: true
end
