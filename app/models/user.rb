# frozen_string_literal: true

class User < ApplicationRecord
  unless const_defined?(:MAX_CHARACTERS)
    MAX_CHARACTERS = 5
  end

  rolify

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :confirmable, :trackable, :timeoutable

  has_many :user_sessions, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :chat_channels, through: :chat_channel_memberships
  has_many :chat_messages, foreign_key: :sender_id, dependent: :nullify
  has_one :currency_wallet, dependent: :destroy
  has_many :ignore_list_entries, dependent: :destroy
  has_many :ignored_users, through: :ignore_list_entries, source: :ignored_user
  has_many :ignored_by_entries,
    class_name: "IgnoreListEntry",
    foreign_key: :ignored_user_id,
    dependent: :destroy
  has_many :ignored_by_users, through: :ignored_by_entries, source: :user
  has_many :arena_participations, dependent: :destroy
  has_many :arena_matches, through: :arena_participations
  after_create :assign_default_role
  after_create :ensure_currency_wallet!
  before_validation :ensure_profile_name

  scope :verified, -> { where.not(confirmed_at: nil) }

  validates :profile_name, presence: true, uniqueness: true, length: {maximum: 32}

  def verified_for_social_features?
    confirmed?
  end

  def ensure_social_features!
    return if verified_for_social_features?

    raise Pundit::NotAuthorizedError, "Email verification required"
  end

  def moderator?
    has_any_role?(:moderator, :gm, :admin)
  end

  def character
    characters.order(:created_at).first
  end

  def ensure_playable_character!
    character || characters.create!(name: next_character_name)
  end

  def suspended?
    suspended_until.present? && suspended_until.future?
  end

  def timeout_in
    30.minutes
  end

  def active_session_for(device_id)
    user_sessions.find_by(device_id: device_id)
  end

  def mark_last_seen!(timestamp: Time.current)
    update_columns(last_seen_at: timestamp)
  end

  def ignoring?(other_user)
    return false if other_user.blank?

    ignore_list_entries.exists?(ignored_user: other_user)
  end

  def ignored_by?(other_user)
    return false if other_user.blank?

    ignored_by_entries.exists?(user: other_user)
  end

  private

  def ensure_profile_name
    return if profile_name.present?

    base = email.to_s.split("@").first.presence || "adventurer"
    candidate = base.parameterize.presence || "adventurer"
    suffix = 1

    while User.where.not(id: id).exists?(profile_name: candidate)
      suffix += 1
      candidate = "#{base.parameterize}-#{suffix}"
    end

    self.profile_name = candidate
  end

  def assign_default_role
    add_role(:player) unless roles.exists?
  end

  def ensure_currency_wallet!
    create_currency_wallet!(nv_balance: 0) unless currency_wallet
  end

  def next_character_name
    base = profile_name.presence || email.to_s.split("@").first.presence || "Hero"
    normalized = base.to_s.gsub(/[^a-zA-Z0-9_]/, "_").squeeze("_").delete_prefix("_").delete_suffix("_")
    normalized = "Hero" if normalized.blank?
    normalized = normalized.first(Character::MAX_NAME_LENGTH)
    candidate = normalized
    suffix = 1

    while Character.exists?(name: candidate)
      suffix += 1
      suffix_text = suffix.to_s
      candidate = "#{normalized.first(Character::MAX_NAME_LENGTH - suffix_text.length)}#{suffix_text}"
    end

    candidate
  end
end
