# frozen_string_literal: true

class GroupListing < ApplicationRecord
  LISTING_TYPES = {
    party: 0,
    guild: 1,
    profession_commission: 2
  }.freeze

  STATUSES = {
    open: 0,
    filled: 1,
    closed: 2
  }.freeze

  enum :listing_type, LISTING_TYPES
  enum :status, STATUSES

  belongs_to :owner, class_name: "User"
  belongs_to :guild, optional: true
  belongs_to :profession, optional: true
  belongs_to :party, optional: true

  validates :title, presence: true
  validates :listing_type, presence: true

  scope :active, -> { open.order(updated_at: :desc) }
end
