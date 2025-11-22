# frozen_string_literal: true

class QuestChain < ApplicationRecord
  has_many :quests, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
end
