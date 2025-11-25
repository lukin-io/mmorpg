# frozen_string_literal: true

# ClanQuest binds authored quest templates (escort caravans, craft supplies,
# clear raids) to a specific clan. It tracks progress toward cooperative
# objectives and rewards XP once requirements are met.
#
# Usage:
#   quest = clan.clan_quests.create!(quest_key: "defend_caravans", requirements: {"escort_runs" => 3})
#   quest.record_progress!("escort_runs", 1)
class ClanQuest < ApplicationRecord
  enum :status, {
    active: 0,
    completed: 1,
    expired: 2
  }

  belongs_to :clan
  belongs_to :quest, optional: true
  has_many :clan_quest_contributions, dependent: :destroy

  validates :quest_key, presence: true

  def record_progress!(metric, amount)
    updated = progress.dup
    updated[metric.to_s] = updated.fetch(metric.to_s, 0) + amount
    self.progress = updated
    save!
  end

  def requirement_for(metric)
    requirements.fetch(metric.to_s, 0).to_i
  end

  def requirement_met?(metric)
    progress.fetch(metric.to_s, 0).to_i >= requirement_for(metric)
  end

  def complete_if_ready!
    return unless requirements.keys.all? { |key| requirement_met?(key) }

    update!(status: :completed)
  end
end
