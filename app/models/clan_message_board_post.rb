# frozen_string_literal: true

class ClanMessageBoardPost < ApplicationRecord
  belongs_to :clan
  belongs_to :author, class_name: "User"

  validates :title, :body, :published_at, presence: true

  scope :recent, -> { order(pinned: :desc, published_at: :desc) }
end
