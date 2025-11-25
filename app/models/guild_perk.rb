# frozen_string_literal: true

class GuildPerk < ApplicationRecord
  belongs_to :guild
  belongs_to :granted_by, class_name: "User", optional: true

  validates :perk_key, presence: true
  validates :source_level, numericality: {greater_than: 0}

  scope :ordered, -> { order(source_level: :asc) }
end
