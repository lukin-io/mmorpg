# frozen_string_literal: true

# One player's selected side while a group application assembles. Completed
# application memberships remain historical; only open applications reserve players.
class ArenaApplicationMembership < ApplicationRecord
  belongs_to :arena_application
  belongs_to :character

  validates :team, inclusion: {in: %w[a b]}
  validates :character_id, uniqueness: {scope: :arena_application_id}
end
