# frozen_string_literal: true

class TitleGrant < ApplicationRecord
  belongs_to :user
  belongs_to :title

  scope :equipped, -> { where(equipped: true) }

  validates :source, presence: true
end
