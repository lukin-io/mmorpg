# frozen_string_literal: true

class FortressSiegeParticipant < ApplicationRecord
  SIDES = %w[attack defense].freeze

  belongs_to :world_fortress
  belongs_to :clan
  belongs_to :character

  validates :side, inclusion: {in: SIDES}
  validates :wave_key, presence: true
end
