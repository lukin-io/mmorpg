# frozen_string_literal: true

class Mount < ApplicationRecord
  belongs_to :user

  validates :name, :mount_type, presence: true
end
