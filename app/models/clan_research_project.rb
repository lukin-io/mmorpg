# frozen_string_literal: true

# ClanResearchProject represents a research track tier (resource yield,
# crafting speed, etc.). Contributions push progress toward completion and,
# once finished, unlock deterministic buffs stored in `unlocks_payload`.
#
# Usage:
#   project = clan.clan_research_projects.create!(project_key: "resource_yield:1", requirements: {...})
#   project.apply_contribution!("refined_lumber" => 10)
class ClanResearchProject < ApplicationRecord
  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2
  }

  belongs_to :clan

  validates :project_key, presence: true

  def apply_contribution!(resource_key:, amount:)
    updated = progress.fetch("crafting", {}).dup
    updated[resource_key] = updated.fetch(resource_key, 0) + amount
    self.progress = progress.merge("crafting" => updated)
    save!
  end

  def completed?
    status == "completed"
  end
end
