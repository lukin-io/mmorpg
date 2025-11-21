# frozen_string_literal: true

class User < ApplicationRecord
  rolify

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :confirmable, :trackable, :timeoutable

  has_many :purchases, dependent: :nullify
  has_many :user_sessions, dependent: :destroy
  has_many :premium_token_ledger_entries, dependent: :destroy
  has_many :audit_logs, foreign_key: :actor_id, dependent: :nullify
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :chat_channels, through: :chat_channel_memberships
  has_many :chat_messages, foreign_key: :sender_id, dependent: :nullify
  has_many :friendships, foreign_key: :requester_id, dependent: :destroy
  has_many :incoming_friendships, class_name: "Friendship", foreign_key: :receiver_id, dependent: :destroy
  has_many :mail_messages, foreign_key: :sender_id, dependent: :nullify
  has_many :received_mail_messages, class_name: "MailMessage", foreign_key: :recipient_id, dependent: :destroy
  has_many :chat_reports, foreign_key: :reporter_id, dependent: :nullify
  has_many :chat_moderation_actions, foreign_key: :target_user_id, dependent: :destroy
  has_many :moderation_actions_as_actor,
    class_name: "ChatModerationAction",
    foreign_key: :actor_id,
    dependent: :nullify
  has_many :guild_memberships, dependent: :destroy
  has_many :guilds, through: :guild_memberships
  has_many :guild_applications, foreign_key: :applicant_id, dependent: :destroy
  has_many :guilds_led, class_name: "Guild", foreign_key: :leader_id, dependent: :nullify
  has_many :guild_bank_entries, foreign_key: :actor_id, dependent: :nullify
  has_many :clan_memberships, dependent: :destroy
  has_many :clans, through: :clan_memberships
  has_many :clans_led, class_name: "Clan", foreign_key: :leader_id, dependent: :nullify
  has_one :currency_wallet, dependent: :destroy
  has_many :profession_progresses, dependent: :destroy
  has_many :crafting_jobs, dependent: :nullify
  has_many :achievement_grants, dependent: :destroy
  has_many :housing_plots, dependent: :destroy
  has_many :pet_companions, dependent: :destroy
  has_many :mounts, dependent: :destroy

  after_create :assign_default_role
  after_create :ensure_currency_wallet!

  scope :verified, -> { where.not(confirmed_at: nil) }

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

  def timeout_in
    30.minutes
  end

  def active_session_for(device_id)
    user_sessions.find_by(device_id: device_id)
  end

  def mark_last_seen!(timestamp: Time.current)
    update_columns(last_seen_at: timestamp)
  end

  private

  def assign_default_role
    add_role(:player) unless roles.exists?
  end

  def ensure_currency_wallet!
    create_currency_wallet!(gold_balance: 0, silver_balance: 0, premium_tokens_balance: premium_tokens_balance) unless currency_wallet
  end
end
