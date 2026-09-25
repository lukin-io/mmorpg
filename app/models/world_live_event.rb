# frozen_string_literal: true

class WorldLiveEvent < ApplicationRecord
  KINDS = %w[
    tournament_fish
    tournament_chaos
    random_ambush
    city_attack
    season_fair
    sector_siege
  ].freeze
  STATUSES = %w[active ended].freeze

  validates :kind, inclusion: {in: KINDS}
  validates :status, inclusion: {in: STATUSES}
  validates :event_key, presence: true, uniqueness: true
  validates :starts_at, :ends_at, presence: true

  scope :active, -> { where(status: "active").where("ends_at > ?", Time.current) }
  scope :of_kind, ->(kind) { where(kind: kind.to_s) }

  def title
    I18n.locale.to_s.start_with?("ru") ? title_ru : title_en
  end

  def body
    I18n.locale.to_s.start_with?("ru") ? body_ru : body_en
  end

  def active?
    status == "active" && ends_at > Time.current
  end

  def end!
    return unless status == "active"

    update!(status: "ended")
    Game::WorldEvents::TournamentScore.finalize!(self) if kind.to_s.start_with?("tournament_")
  end
end
