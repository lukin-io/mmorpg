# frozen_string_literal: true

class User < ApplicationRecord
  unless const_defined?(:MAX_CHARACTERS)
    MAX_CHARACTERS = 5
  end
  MAX_PROFILE_NAME_LENGTH = 20
  PROFILE_NAME_FORMAT = /\A[\p{L}\p{N}](?:[\p{L}\p{N}_ -]{0,18}[\p{L}\p{N}])?\z/u

  rolify

  # Sandbox/Railway: no SMTP — keep confirmable schema but allow login without email.
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :confirmable, :trackable, :timeoutable

  before_create :sandbox_skip_confirmation
  before_validation :normalize_profile_name

  def sandbox_skip_confirmation
    return unless ENV["SANDBOX_OPEN_AUTH"] == "1"

    skip_confirmation!
    skip_confirmation_notification!
  end

  has_many :user_sessions, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :chat_channels, through: :chat_channel_memberships
  has_many :chat_messages, foreign_key: :sender_id, dependent: :nullify
  has_many :game_events,
    foreign_key: :recipient_id,
    inverse_of: :recipient,
    dependent: :restrict_with_error
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
  has_many :management_audit_events,
    foreign_key: :actor_id,
    inverse_of: :actor,
    dependent: :restrict_with_error
  after_create :assign_default_role
  after_create :ensure_currency_wallet!

  scope :verified, -> { where.not(confirmed_at: nil) }

  validates :profile_name,
    presence: true,
    uniqueness: {case_sensitive: false},
    length: {minimum: 2, maximum: MAX_PROFILE_NAME_LENGTH},
    format: {with: PROFILE_NAME_FORMAT, message: :invalid_nickname}

  def verified_for_social_features?
    confirmed?
  end

  def ensure_social_features!
    return if verified_for_social_features?

    raise Pundit::NotAuthorizedError, I18n.t("game.flashes.email_verification_required")
  end

  def moderator?
    has_any_role?(:moderator, :gm, :admin)
  end

  def character
    characters.order(:created_at, :id).first
  end

  def ensure_playable_character!
    playable = character || characters.create!(name: next_character_name)
    Game::World::StarterKit.new(character: playable).call
    Game::Quests::Journal.new(character: playable).ensure_starter!
    playable
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

  def normalize_profile_name
    self.profile_name = profile_name.to_s.strip.squeeze(" ")
    self.profile_name = nil if profile_name.blank?
  end

  def assign_default_role
    add_role(:player) unless roles.exists?
  end

  def ensure_currency_wallet!
    create_currency_wallet!(nv_balance: 0) unless currency_wallet
  end

  def next_character_name
    base = profile_name.presence || email.to_s.split("@").first.presence || "player"
    normalized = base.to_s.strip.gsub(/[^\p{L}\p{N}_ -]/u, "").squeeze(" ").tr(" ", "_")
    normalized = normalized.squeeze("_").delete_prefix("_").delete_suffix("_")
    normalized = "player" if normalized.blank?
    normalized = normalized.first(Character::MAX_NAME_LENGTH)
    candidate = normalized
    suffix = 1

    while Character.where("LOWER(name) = ?", candidate.downcase).exists?
      suffix += 1
      suffix_text = suffix.to_s
      candidate = "#{normalized.first(Character::MAX_NAME_LENGTH - suffix_text.length)}#{suffix_text}"
    end

    candidate
  end
end