# frozen_string_literal: true

class QuestChain < ApplicationRecord
  has_many :quest_chapters, -> { order(:position) }, dependent: :destroy
  has_many :quests, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
end
