# frozen_string_literal: true

class IntegrationToken < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :webhook_endpoints, dependent: :destroy

  before_validation :assign_token, on: :create

  validates :name, :token, presence: true
  validates :token, uniqueness: true

  private

  def assign_token
    self.token ||= SecureRandom.hex(20)
  end
end
