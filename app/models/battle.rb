# frozen_string_literal: true

# Battle persists PvE/PvP encounters, initiative order, and combat status.
class Battle < ApplicationRecord
  PVP_MODES = %w[duel skirmish arena clan].freeze

  enum :battle_type, {
    pve: 0,
    pvp: 1,
    arena: 2
  }

  enum :status, {
    pending: 0,
    active: 1,
    completed: 2
  }

  belongs_to :zone, optional: true
  belongs_to :initiator, class_name: "Character"
  has_many :battle_participants, dependent: :destroy
  has_many :combat_log_entries, dependent: :destroy
  has_one :combat_analytics_report, dependent: :destroy

  validates :turn_number, numericality: {greater_than: 0}
  validates :pvp_mode, inclusion: {in: PVP_MODES}, allow_nil: true

  def next_sequence_for(round_number)
    combat_log_entries.where(round_number:).maximum(:sequence).to_i + 1
  end

  def ladder_type
    return "arena" if battle_type == "arena"
    return pvp_mode if pvp_mode.present?

    nil
  end
end
