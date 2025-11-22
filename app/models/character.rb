# frozen_string_literal: true

class Character < ApplicationRecord
  MAX_NAME_LENGTH = 30
  ALIGNMENTS = {
    neutral: "neutral",
    alliance: "alliance",
    rebellion: "rebellion"
  }.freeze

  belongs_to :user
  belongs_to :character_class, optional: true
  belongs_to :guild, optional: true
  belongs_to :clan, optional: true
  belongs_to :secondary_specialization, class_name: "ClassSpecialization", optional: true

  has_one :position, class_name: "CharacterPosition", dependent: :destroy
  has_one :inventory, dependent: :destroy
  has_one :arena_ranking, dependent: :destroy

  has_many :character_skills, dependent: :destroy
  has_many :skill_nodes, through: :character_skills
  has_many :battle_participants, dependent: :destroy
  has_many :battles, through: :battle_participants
  has_many :initiated_battles, class_name: "Battle", foreign_key: :initiator_id, dependent: :nullify
  has_many :quest_assignments, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: {maximum: MAX_NAME_LENGTH}
  validates :level, numericality: {greater_than: 0}
  validates :experience, numericality: {greater_than_or_equal_to: 0}
  validates :stat_points_available, :skill_points_available, numericality: {greater_than_or_equal_to: 0}
  validates :reputation, numericality: {greater_than_or_equal_to: 0}
  validates :alignment_score, numericality: true
  validates :faction_alignment, inclusion: {in: ALIGNMENTS.values}

  validate :respect_character_limit, on: :create

  before_validation :inherit_memberships, on: :create
  after_create :ensure_inventory!

  def stats
    base = (character_class&.base_stats || {}).transform_keys(&:to_sym)
    allocated_stats.each do |stat, value|
      key = stat.to_sym
      base[key] = base.fetch(key, 0) + value.to_i
    end
    Game::Systems::StatBlock.new(base:)
  end

  private

  def inherit_memberships
    return unless user

    self.guild ||= user.primary_guild
    self.clan ||= user.primary_clan
  end

  def respect_character_limit
    return unless user

    if user.characters.count >= User::MAX_CHARACTERS
      errors.add(:base, "character limit reached")
    end
  end

  def ensure_inventory!
    create_inventory!(slot_capacity: 30, weight_capacity: 100) unless inventory
  end
end
