# frozen_string_literal: true

class Clan < ApplicationRecord
  # Soft-release Ashen roles (player-facing RU: глава / зам / казначей / работник).
  ROLES = %w[leader deputy treasurer worker].freeze
  ALIGNMENTS = %w[light dark none].freeze
  ROLE_RANK = {
    "leader" => 4,
    "deputy" => 3,
    "treasurer" => 2,
    "worker" => 1
  }.freeze

  belongs_to :leader_character, class_name: "Character"
  has_many :clan_memberships, dependent: :destroy
  has_many :characters, through: :clan_memberships
  has_many :clan_treasury_items, dependent: :destroy
  has_many :clan_invitations, dependent: :destroy
  has_many :world_fortresses, foreign_key: :owner_clan_id, inverse_of: :owner_clan, dependent: :nullify

  validates :key, :name, :tag, presence: true
  validates :key, :tag, uniqueness: true
  validates :tag, length: {in: 2..6}
  validates :alignment, inclusion: {in: ALIGNMENTS}
  validates :treasury_nv, numericality: {greater_than_or_equal_to: 0}

  def member?(character)
    clan_memberships.exists?(character_id: character.id)
  end

  def membership_for(character)
    clan_memberships.find_by(character_id: character.id)
  end

  def member_ids
    clan_memberships.pluck(:character_id)
  end

  def role_of(character)
    membership_for(character)&.role
  end

  def can_manage?(character)
    %w[leader deputy].include?(role_of(character))
  end

  def can_invite?(character)
    %w[leader deputy].include?(role_of(character))
  end

  def can_lock_treasury?(character)
    %w[leader deputy treasurer].include?(role_of(character))
  end

  def can_withdraw_treasury?(character)
    role = role_of(character)
    return false if role.blank?
    return true if %w[leader treasurer].include?(role)
    return true if !treasury_locked? && %w[deputy worker].include?(role)

    false
  end

  def can_donate?(character)
    member?(character)
  end

  def alignment_label
    I18n.t("game.buildings.law_alignment.#{alignment}", default: alignment)
  end
end
