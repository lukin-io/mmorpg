# frozen_string_literal: true

# ClanLogEntry is the immutable clan history for treasury transfers, promotions,
# and war declarations. Entries are created via Clans::LogWriter and surfaced to
# clan leaders.
#
# Usage:
#   Clans::LogWriter.new(clan: clan).record!(action: "treasury.withdraw", actor: user, metadata: {...})
class ClanLogEntry < ApplicationRecord
  belongs_to :clan
  belongs_to :actor, class_name: "User", optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
