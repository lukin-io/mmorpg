# frozen_string_literal: true

class Quest < ApplicationRecord
  enum :quest_type, {
    main_story: 0,
    side: 1,
    daily: 2,
    dynamic: 3,
    raid: 4
  }

  belongs_to :quest_chain, optional: true
  has_many :quest_objectives, dependent: :destroy
  has_many :quest_assignments, dependent: :destroy
  has_many :cutscene_events, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
  validates :sequence, numericality: {greater_than: 0}

  scope :chronological, -> { order(:chapter, :sequence) }

  def next_in_chain
    return unless quest_chain

    quest_chain.quests.where("sequence > ?", sequence).order(:sequence).first
  end
end
