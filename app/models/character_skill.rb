# frozen_string_literal: true

# CharacterSkill links unlocked skill nodes to characters with timestamps.
class CharacterSkill < ApplicationRecord
  belongs_to :character
  belongs_to :skill_node

  validates :unlocked_at, presence: true
end
