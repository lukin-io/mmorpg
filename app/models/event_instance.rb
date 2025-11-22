# frozen_string_literal: true

class EventInstance < ApplicationRecord
  enum :status, {
    scheduled: 0,
    active: 1,
    concluded: 2,
    cancelled: 3
  }

  belongs_to :game_event
  has_many :arena_tournaments, dependent: :destroy
  has_many :community_objectives, dependent: :destroy

  validates :starts_at, :ends_at, presence: true

  def announcer_npc
    return unless announcer_npc_key

    Game::World::PopulationDirectory.instance.npc(announcer_npc_key)
  end
end
