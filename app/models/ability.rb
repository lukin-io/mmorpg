# frozen_string_literal: true

# Ability stores class-specific active/passive skills consumed by the combat engine.
class Ability < ApplicationRecord
  KINDS = %w[active passive reaction].freeze

  belongs_to :character_class

  validates :name, presence: true
  validates :kind, inclusion: {in: KINDS}
end

