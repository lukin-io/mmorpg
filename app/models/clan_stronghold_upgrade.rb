# frozen_string_literal: true

# ClanStrongholdUpgrade tracks upgrade jobs running on the clan stronghold
# (war rooms, command halls, vendor unlocks). Requirements/progress are stored
# as JSON so design can tweak costs without schema churn.
#
# Usage:
#   clan.clan_stronghold_upgrades.create!(upgrade_key: "war_room", requirements: {...})
#   upgrade.in_progress!; upgrade.apply_contribution!("steel_ingot" => 10)
class ClanStrongholdUpgrade < ApplicationRecord
  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2
  }

  belongs_to :clan

  validates :upgrade_key, presence: true

  def percent_complete
    requirement_total = requirements.fetch("crafted_items", []).sum { |item| item["quantity"].to_i }
    return 0 if requirement_total.zero?

    delivered = progress.fetch("crafted_items", {}).values.sum
    ((delivered.to_f / requirement_total) * 100).round(1)
  end

  def apply_contribution!(item_key:, amount:)
    updated = progress.fetch("crafted_items", {}).dup
    updated[item_key] = updated.fetch(item_key, 0) + amount
    self.progress = progress.merge("crafted_items" => updated)
    save!
  end
end
