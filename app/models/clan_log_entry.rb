# frozen_string_literal: true

# ClanLogEntry is the immutable audit log for treasury transfers, promotions,
# war declarations, and moderation rollbacks. Entries are created via
# Clans::LogWriter and surfaced to leaders/GMs for dispute resolution.
#
# Usage:
#   Clans::LogWriter.new(clan: clan).record!(action: "treasury.withdraw", actor: user, metadata: {...})
class ClanLogEntry < ApplicationRecord
  belongs_to :clan
  belongs_to :actor, class_name: "User", optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
