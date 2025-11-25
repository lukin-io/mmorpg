# frozen_string_literal: true

# ClanTreasuryTransaction logs every deposit/withdrawal performed against a
# clan's shared treasury with metadata about who triggered it and why.
# Entries are created exclusively via Clans::TreasuryService so role limits
# and audit requirements stay consistent.
#
# Usage:
#   Clans::TreasuryService.new(clan: clan, actor: user).deposit!(currency: :gold, amount: 1000, reason: "quest_reward")
class ClanTreasuryTransaction < ApplicationRecord
  belongs_to :clan
  belongs_to :actor, class_name: "User"

  validates :currency_type, inclusion: {in: %w[gold silver premium_tokens]}
  validates :amount, numericality: {other_than: 0}
  validates :reason, presence: true
end
