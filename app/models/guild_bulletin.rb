# frozen_string_literal: true

class GuildBulletin < ApplicationRecord
  belongs_to :guild
  belongs_to :author, class_name: "User"

  validates :title, :body, presence: true

  scope :pinned_first, -> { order(pinned: :desc, published_at: :desc) }
end
