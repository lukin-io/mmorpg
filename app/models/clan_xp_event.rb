# frozen_string_literal: true

# ClanXpEvent is an append-only ledger that captures how much experience a clan
# earned from a particular source (quests, wars, research). It powers graphs,
# audits, and the XP progression service.
#
# Usage:
#   clan.clan_xp_events.create!(source: "clan_quest", amount: 500, recorded_at: Time.current)
#   clan.clan_xp_events.recent.limit(10)
class ClanXpEvent < ApplicationRecord
  belongs_to :clan

  validates :source, :amount, :recorded_at, presence: true
  validates :amount, numericality: {greater_than: 0}

  scope :recent, -> { order(recorded_at: :desc) }
end
