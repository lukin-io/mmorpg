# frozen_string_literal: true

# ClanApplication stores recruitment submissions (vetting answers, referrals,
# status transitions). Clans::ApplicationPipeline owns the workflow to create
# or review applications and to auto-accept when rules match.
#
# Usage:
#   application = clan.clan_applications.create!(applicant: user, vetting_answers: {...})
#   Clans::ApplicationPipeline.new(clan: clan, reviewer: officer).review!(application:, decision: :approved)
class ClanApplication < ApplicationRecord
  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    auto_accepted: 3
  }

  belongs_to :clan
  belongs_to :applicant, class_name: "User"
  belongs_to :character, optional: true
  belongs_to :referral_user, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  validates :vetting_answers, presence: true

  scope :awaiting_review, -> { where(status: :pending) }
end
