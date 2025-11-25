# frozen_string_literal: true

# ClanQuestContribution captures individual character contributions toward a
# clan quest objective so rewards/credits can be surfaced later.
#
# Usage:
#   clan_quest.clan_quest_contributions.create!(character: character, contribution_type: "escort_runs", amount: 1)
class ClanQuestContribution < ApplicationRecord
  belongs_to :clan_quest
  belongs_to :character

  validates :contribution_type, presence: true
  validates :amount, numericality: {greater_than: 0}
end
