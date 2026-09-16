# frozen_string_literal: true

# A quoted treatment is an offer, never a debit. The patient must accept a paid
# offer; the service revalidates both characters, license, bag and injury then.
class InjuryTreatment < ApplicationRecord
  belongs_to :character_injury
  belongs_to :healer, class_name: "Character"
  belongs_to :inventory_item, optional: true
  validates :status, inclusion: {in: %w[pending completed declined]}
  validates :price, numericality: {only_integer: true, in: 0..7000}
  validates :expires_at, presence: true
end
