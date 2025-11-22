# frozen_string_literal: true

class CutsceneEvent < ApplicationRecord
  belongs_to :quest, optional: true

  validates :key, presence: true, uniqueness: true
end
