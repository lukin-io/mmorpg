# frozen_string_literal: true

# Outdoor fortress / castle claim + clan siege state for the playable region.
class WorldFortress < ApplicationRecord
  KINDS = %w[fortress castle].freeze
  SIEGE_OPEN_HOUR = 14
  SIEGE_CLOSE_HOUR = 22

  belongs_to :owner_character, class_name: "Character", optional: true
  belongs_to :owner_clan, class_name: "Clan", optional: true
  has_many :fortress_buildings, dependent: :destroy
  has_many :fortress_siege_participants, dependent: :destroy

  validates :zone, :fortress_key, :name, :kind, presence: true
  validates :fortress_key, uniqueness: true
  validates :kind, inclusion: {in: KINDS}
  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :x, uniqueness: {scope: [:zone, :y]}

  scope :active, -> { where(active: true) }
  scope :in_zone, ->(zone_name) { where(zone: zone_name) }

  def fortress? = kind == "fortress"
  def castle? = kind == "castle"
  def under_siege? = siege_ends_at.present? && siege_ends_at > Time.current
  def owned? = owner_clan_id.present? || owner_character_id.present?

  def owner_name
    owner_clan&.name || owner_character&.name
  end

  def siege_window_open?(now: Time.current)
    hour = now.in_time_zone.hour
    hour >= SIEGE_OPEN_HOUR && hour < SIEGE_CLOSE_HOUR
  end

  def ensure_default_buildings!
    FortressBuilding::CATALOG.each do |key, definition|
      fortress_buildings.find_or_create_by!(building_key: key) do |row|
        row.name = definition.fetch("name")
        row.level = 1
        row.bonuses = definition.fetch("bonuses_per_level").transform_values(&:to_i)
      end
    end
  end
end
