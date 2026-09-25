# frozen_string_literal: true

class ClanInvitation < ApplicationRecord
  STATUSES = %w[pending accepted declined revoked].freeze

  belongs_to :clan
  belongs_to :inviter_character, class_name: "Character"
  belongs_to :invitee_character, class_name: "Character"

  validates :status, inclusion: {in: STATUSES}

  scope :pending, -> { where(status: "pending") }
  scope :for_character, ->(character) { where(invitee_character_id: character.id) }

  def pending? = status == "pending"
end
