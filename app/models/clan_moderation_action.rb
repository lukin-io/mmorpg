# frozen_string_literal: true

# ClanModerationAction records interventions taken by moderators/GMs against a
# clan (rollbacks, dissolutions, disputes). Stored separately from ClanLogEntry
# so staff actions are easy to filter and audit.
#
# Usage:
#   ClanModerationAction.create!(clan:, gm_user: current_user, action_type: "rollback", notes: "Reverted abuse")
class ClanModerationAction < ApplicationRecord
  belongs_to :clan
  belongs_to :gm_user, class_name: "User"
  belongs_to :target, polymorphic: true, optional: true

  validates :action_type, presence: true
end
